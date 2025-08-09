//
//  AudioManager.swift
//  FrequencyFinder
//
//  Created by David Nyman on 8/9/25.
//

import AVFoundation
import Accelerate
import Combine

class AudioManager: ObservableObject {
    @Published var frequency: Float = 0.0
    @Published var note: String = ""
    @Published var cents: Float = 0.0
    @Published var isListening: Bool = false
    @Published var amplitude: Float = 0.0
    @Published var debugInfo: String = ""
    @Published var tuningSession = TuningSession()
    
    private var lastRecordTime: Date = Date()
    private let recordingInterval: TimeInterval = 0.5 // Record every 0.5 seconds
    private var isProcessingBuffer = false // Prevent concurrent processing
    
    private var audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private let fftSetup: FFTSetup
    private let bufferSize: Int = 4096
    private var sampleRate: Float = 44100.0
    private let log2n: UInt
    
    init() {
        log2n = UInt(round(log2(Double(bufferSize))))
        fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))!
        setupAudioSession()
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
        stopListening()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startListening() {
        guard !isListening else { 
            print("🎤 AudioManager: Already listening, skipping")
            return 
        }
        
        print("🎤 AudioManager: Starting to listen...")
        
        do {
            print("🎤 AudioManager: Getting input node...")
            inputNode = audioEngine.inputNode
            let inputFormat = inputNode?.outputFormat(forBus: 0)
            print("🎤 AudioManager: Input format: \(String(describing: inputFormat))")
            
            // Update sample rate to match actual input format
            if let format = inputFormat {
                sampleRate = Float(format.sampleRate)
                print("🎤 AudioManager: Updated sample rate to: \(sampleRate) Hz")
            }
            
            print("🎤 AudioManager: Installing tap with buffer size: \(bufferSize)")
            inputNode?.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: inputFormat) { [weak self] buffer, time in
                // Add thread safety check
                guard let self = self, self.isListening else { return }
                self.processAudioBuffer(buffer)
            }
            
            print("🎤 AudioManager: Starting audio engine...")
            try audioEngine.start()
            isListening = true
            print("✅ AudioManager: Successfully started listening")
        } catch {
            print("❌ AudioManager: Failed to start audio engine: \(error)")
        }
    }
    
    func stopListening() {
        guard isListening else { 
            print("🎤 AudioManager: Already stopped, skipping")
            return 
        }
        
        print("🎤 AudioManager: Stopping audio processing...")
        print("🎤 AudioManager: Removing tap...")
        inputNode?.removeTap(onBus: 0)
        print("🎤 AudioManager: Stopping engine...")
        audioEngine.stop()
        isListening = false
        print("✅ AudioManager: Successfully stopped")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Prevent concurrent processing to avoid threading issues
        guard !isProcessingBuffer else { 
            print("⚠️ AudioManager: Skipping buffer - already processing")
            return 
        }
        isProcessingBuffer = true
        defer { isProcessingBuffer = false }
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        
        // Ensure we don't exceed buffer size
        let processCount = min(frameCount, bufferSize)
        
        // Copy and pad samples if necessary
        var samples = [Float](repeating: 0.0, count: bufferSize)
        samples.withUnsafeMutableBufferPointer { samplesPtr in
            samplesPtr.baseAddress!.update(from: channelData, count: processCount)
        }
        
        // Calculate RMS amplitude for signal strength detection
        var rms: Float = 0.0
        vDSP_rmsqv(samples, 1, &rms, UInt(processCount))
        let amplitude = rms
        
        // Debugging: track signal strength
        let amplitudeDB = 20 * log10(max(amplitude, 1e-6)) // Convert to dB
        
        // Apply amplitude threshold - only process if signal is strong enough
        let minAmplitudeDB: Float = -50.0  // Adjust this threshold as needed
        guard amplitudeDB > minAmplitudeDB else {
            DispatchQueue.main.async {
                self.amplitude = amplitude
                self.debugInfo = "Signal too weak: \(String(format: "%.1f", amplitudeDB)) dB"
                self.frequency = 0.0
                self.note = ""
                self.cents = 0.0
            }
            return
        }
        
        // Apply window function (Hanning window) - optimized
        var window = [Float](repeating: 0.0, count: bufferSize)
        vDSP_hann_window(&window, UInt(bufferSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(samples, 1, window, 1, &samples, 1, UInt(bufferSize))
        

        // Prepare for FFT - optimized memory handling
        var realParts = [Float](repeating: 0.0, count: bufferSize / 2)
        var imagParts = [Float](repeating: 0.0, count: bufferSize / 2)

        
        samples.withUnsafeBufferPointer { samplesPtr in
            realParts.withUnsafeMutableBufferPointer { realPtr in
                imagParts.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                    
                    // Convert real input to complex format
                    samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, UInt(bufferSize / 2))
                    }
                    
                    // Perform FFT
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, Int32(FFT_FORWARD))
                }
            }
        }
        
        // Calculate magnitude spectrum
        var magnitudes = [Float](repeating: 0.0, count: bufferSize / 2)
        realParts.withUnsafeMutableBufferPointer { realPtr in
            imagParts.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, UInt(bufferSize / 2))
            }
        }
        
        // Find peak frequency with better noise filtering
        let (peakFrequency, confidence) = findPeakFrequencyWithConfidence(magnitudes: magnitudes)
        
        // Update UI with debugging information
        DispatchQueue.main.async {
            self.amplitude = amplitude
            self.debugInfo = "Amp: \(String(format: "%.1f", amplitudeDB))dB, Conf: \(String(format: "%.2f", confidence))"
            
            // Only update frequency if confidence is high enough
            if confidence > 0.3 && peakFrequency >= 40 {
                self.frequency = peakFrequency
                self.updateNoteAndCents(frequency: peakFrequency)
                
                // Record pitch data for history if enough time has passed and we have a valid note
                if !self.note.isEmpty && Date().timeIntervalSince(self.lastRecordTime) >= self.recordingInterval {
                    let pitchData = PitchData(
                        timestamp: Date(),
                        frequency: peakFrequency,
                        note: self.note,
                        cents: self.cents,
                        amplitude: amplitude,
                        confidence: confidence
                    )
                    self.tuningSession.addPitchData(pitchData)
                    self.lastRecordTime = Date()
                }
            } else {
                // Keep previous frequency but clear note if confidence is low
                if confidence < 0.1 {
                    self.frequency = 0.0
                    self.note = ""
                    self.cents = 0.0
                }
            }
        }
    }
    
    private func findPeakFrequency(magnitudes: [Float]) -> Float {
        let (frequency, _) = findPeakFrequencyWithConfidence(magnitudes: magnitudes)
        return frequency
    }
    
    private func findPeakFrequencyWithConfidence(magnitudes: [Float]) -> (frequency: Float, confidence: Float) {
        // Find the index of the maximum magnitude
        var maxIndex: UInt = 0
        var maxValue: Float = 0
        vDSP_maxvi(magnitudes, 1, &maxValue, &maxIndex, UInt(magnitudes.count))
        
        // Skip only DC component (0 Hz) but allow low frequencies down to ~40 Hz
        // With 4096 buffer and 44100 Hz sample rate, bin 1 = ~10.8 Hz, bin 4 = ~43 Hz
        guard maxIndex > 3 else { return (0.0, 0.0) }
        
        // Calculate signal-to-noise ratio for confidence
        let noiseFloor = calculateNoiseFloor(magnitudes: magnitudes, peakIndex: Int(maxIndex))
        let snr = maxValue / max(noiseFloor, 1e-6)
        let confidence = min(1.0, log10(snr) / 2.0) // Normalize SNR to 0-1 confidence
        
        // Require minimum signal strength
        guard maxValue > noiseFloor * 3.0 else { return (0.0, 0.0) } // 3x above noise floor
        
        // Convert bin to frequency
        let binFrequency = Float(maxIndex) * sampleRate / Float(bufferSize)
        
        // Apply parabolic interpolation for better accuracy
        var frequency = binFrequency
        if maxIndex > 0 && maxIndex < magnitudes.count - 1 {
            let y1 = magnitudes[Int(maxIndex) - 1]
            let y2 = magnitudes[Int(maxIndex)]
            let y3 = magnitudes[Int(maxIndex) + 1]
            
            let a = (y1 - 2 * y2 + y3) / 2
            let b = (y3 - y1) / 2
            
            if abs(a) > 0.0001 {
                let xOffset = -b / (2 * a)
                frequency = (Float(maxIndex) + xOffset) * sampleRate / Float(bufferSize)
            }
        }
        
        return (frequency, max(0.0, confidence))
    }
    
    private func calculateNoiseFloor(magnitudes: [Float], peakIndex: Int) -> Float {
        // Calculate average magnitude excluding the peak and its neighbors
        var sum: Float = 0.0
        var count = 0
        
        // Start from bin 4 to include low frequencies in noise floor calculation
        for i in 4..<magnitudes.count {
            if abs(i - peakIndex) > 5 { // Skip peak and neighbors
                sum += magnitudes[i]
                count += 1
            }
        }
        
        return count > 0 ? sum / Float(count) : 0.0
    }
    
    private func updateNoteAndCents(frequency: Float) {
        guard frequency >= 40 && frequency < 2000 else {
            note = ""
            cents = 0
            return
        }
        
        let noteInfo = frequencyToNote(frequency: frequency)
        note = noteInfo.note
        cents = noteInfo.cents
    }
    
    private func frequencyToNote(frequency: Float) -> (note: String, cents: Float) {
        let A4 = Float(440.0)
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        
        // Calculate the number of semitones from A4
        let semitonesFromA4 = 12 * log2(frequency / A4)
        
        // Round to nearest semitone to get the note
        let nearestSemitone = round(semitonesFromA4)
        let cents = (semitonesFromA4 - nearestSemitone) * 100
        
        // Calculate note index (A4 is index 9 in our array)
        let noteIndex = Int(nearestSemitone) + 9
        let octave = 4 + (noteIndex / 12)
        
        // Handle negative octaves for very low frequencies
        var finalOctave = octave
        var finalNoteInOctave = ((noteIndex % 12) + 12) % 12
        
        // Adjust for negative note indices
        if noteIndex < 0 {
            finalOctave = 4 + (noteIndex - 11) / 12
            finalNoteInOctave = ((noteIndex % 12) + 12) % 12
        }
        
        let noteName = noteNames[finalNoteInOctave]
        return (note: "\(noteName)\(finalOctave)", cents: cents)
    }
}
