import AVFoundation
import Accelerate
import Combine

class AudioManager: NSObject, ObservableObject {
    @Published var frequency: Float = 0.0
    @Published var note: String = ""
    @Published var cents: Float = 0.0
    @Published var isListening: Bool = false
    @Published var amplitude: Float = 0.0
    
    private var audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode!
    
    private var fftSetup: FFTSetup!
    private var log2n: vDSP_Length = 0
    private var bufferSize: Int = 0
    private var window: [Float] = []
    private var isProcessing = false
    
    private let bufferSizeExp = 12
    
    override init() {
        super.init()
        setupAudio()
        setupFFT()
    }
    
    deinit {
        stop()
        if fftSetup != nil {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
    
    private func setupAudio() {
        inputNode = audioEngine.inputNode
        bufferSize = 1 << bufferSizeExp
    }
    
    private func setupFFT() {
        log2n = vDSP_Length(bufferSizeExp)
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        window = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
    }
    
    func start() {
        guard !audioEngine.isRunning else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            // Install tap before starting engine
            let inputFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: inputFormat) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }
            
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stop() {
        guard audioEngine.isRunning else { return }
        
        // Wait for any ongoing processing to finish
        while isProcessing {
            Thread.sleep(forTimeInterval: 0.001)
        }
        
        // Stop engine first, then remove tap
        audioEngine.stop()
        
        // Small delay to ensure engine is fully stopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.inputNode.removeTap(onBus: 0)
        }
        
        // Don't deactivate session immediately, let the system handle it
        // This prevents conflicts with other audio apps
        
        DispatchQueue.main.async {
            self.isListening = false
            self.frequency = 0.0
            self.note = ""
            self.cents = 0.0
            self.amplitude = 0.0
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Prevent concurrent processing
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        
        let frameCount = Int(buffer.frameLength)
        let actualBufferSize = min(frameCount, bufferSize)
        
        var signal = Array(UnsafeBufferPointer(start: channelData, count: actualBufferSize))
        
        if signal.count < bufferSize {
            signal += Array(repeating: 0.0, count: bufferSize - signal.count)
        }
        
        // Calculate RMS for amplitude
        var rms: Float = 0
        vDSP_rmsqv(signal, 1, &rms, vDSP_Length(bufferSize))
        
        // Apply window
        vDSP_vmul(signal, 1, window, 1, &signal, 1, vDSP_Length(bufferSize))
        
        // Perform FFT
        let halfSize = bufferSize / 2
        var realp = [Float](repeating: 0, count: halfSize)
        var imagp = [Float](repeating: 0, count: halfSize)
        
        realp.withUnsafeMutableBufferPointer { realBuffer in
            imagp.withUnsafeMutableBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(realp: realBuffer.baseAddress!, imagp: imagBuffer.baseAddress!)
                
                signal.withUnsafeBufferPointer { signalPtr in
                    signalPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfSize) { complexBuffer in
                        vDSP_ctoz(complexBuffer, 2, &splitComplex, 1, vDSP_Length(halfSize))
                        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                    }
                }
                
                // Calculate magnitude spectrum
                var magnitudes = [Float](repeating: 0, count: halfSize)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfSize))
                
                // Find peak frequency
                var maxIndex: vDSP_Length = 0
                var maxValue: Float = 0
                vDSP_maxvi(magnitudes, 1, &maxValue, &maxIndex, vDSP_Length(halfSize))
                
                let sampleRate = Float(audioEngine.inputNode.outputFormat(forBus: 0).sampleRate)
                let frequency = Float(maxIndex) * sampleRate / Float(bufferSize)
                
                // Only update if we have a strong enough signal
                if maxValue > 0.01 && frequency > 20 && frequency < 2000 {
                    let (noteName, centsValue) = frequencyToNote(frequency)
                    
                    DispatchQueue.main.async {
                        self.frequency = frequency
                        self.note = noteName
                        self.cents = centsValue
                        self.amplitude = rms
                    }
                }
            }
        }
    }
    
    private func frequencyToNote(_ frequency: Float) -> (String, Float) {
        let A4 = Float(440.0)
        let C0 = A4 * pow(2, -4.75)
        
        if frequency <= 0 { return ("", 0) }
        
        let halfStepsBelowMiddleC = 12 * log2(frequency / C0)
        let halfSteps = Int(round(halfStepsBelowMiddleC))
        let cents = (halfStepsBelowMiddleC - Float(halfSteps)) * 100
        
        let octave = halfSteps / 12
        let noteIndex = ((halfSteps % 12) + 12) % 12
        
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteName = "\(noteNames[noteIndex])\(octave)"
        
        return (noteName, cents)
    }
}