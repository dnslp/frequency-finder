/*
 * FFT Implementation Testing
 *
 * Provides comprehensive testing for the FFT implementation migration
 */

import Foundation

/// Test suite for FFT implementation verification
public struct FFTTest {
    
    /// Run all FFT tests
    public static func runAllTests() {
        print("🧪 FFT Implementation Test Suite")
        print("================================")
        
        testBasicFFTFunctionality()
        testPitchTrackingAccuracy()
        runPerformanceBenchmarks()
    }
    
    /// Test basic FFT functionality and accuracy
    private static func testBasicFFTFunctionality() {
        print("\n📊 Basic FFT Functionality Test")
        print("-------------------------------")
        
        // Test with known signal
        let fftSize = 4096
        let sampleRate = 44100.0
        let testFreq = 440.0  // A4
        
        // Generate test signal
        let testSignal = Array(0..<fftSize).map { i in
            Float(sin(2.0 * .pi * testFreq * Double(i) / sampleRate))
        }
        
        // Test both implementations
        let M = Int(log2(Double(fftSize)))
        
        let accelerateFFT = AccelerateFFT(M: M - 1, size: Double(fftSize / 2))
        let zenFFT = ZenFFT(M: M - 1, size: Double(fftSize / 2))
        
        var accelerateBuffer = testSignal
        var zenBuffer = testSignal
        
        accelerateFFT.compute(buf: &accelerateBuffer)
        zenFFT.compute(buf: &zenBuffer)
        
        // Find peaks to verify frequency detection
        let acceleratePeak = findPeakFrequency(fftBuffer: accelerateBuffer, sampleRate: sampleRate)
        let zenPeak = findPeakFrequency(fftBuffer: zenBuffer, sampleRate: sampleRate)
        
        print(String(format: "Expected frequency: %.1f Hz", testFreq))
        print(String(format: "Accelerate detected: %.1f Hz", acceleratePeak))
        print(String(format: "ZenFFT detected:     %.1f Hz", zenPeak))
        
        let accelerateError = abs(acceleratePeak - testFreq) / testFreq * 100
        let zenError = abs(zenPeak - testFreq) / testFreq * 100
        
        print(String(format: "Accelerate error:    %.2f%%", accelerateError))
        print(String(format: "ZenFFT error:        %.2f%%", zenError))
        
        let success = accelerateError < 1.0 && zenError < 1.0
        print(String(format: "Basic test result:   %@", success ? "✅ PASS" : "❌ FAIL"))
    }
    
    /// Test pitch tracking accuracy with both implementations
    private static func testPitchTrackingAccuracy() {
        print("\n🎵 Pitch Tracking Accuracy Test")
        print("-------------------------------")
        
        let sampleRate = 44100.0
        let hopSize = 2048.0
        
        // Test frequencies
        let testFrequencies: [Double] = [82.41, 110.0, 146.83, 220.0, 293.66, 440.0, 587.33]  // Low E to high D
        
        for testFreq in testFrequencies {
            // Test with Accelerate implementation
            FFTConfiguration.defaultImplementation = .accelerate
            var accelerateTracker = ZenPTrack(sampleRate: sampleRate, hopSize: hopSize, peakCount: 20)
            
            // Test with ZenFFT implementation  
            FFTConfiguration.defaultImplementation = .zen
            var zenTracker = ZenPTrack(sampleRate: sampleRate, hopSize: hopSize, peakCount: 20)
            
            // Generate test signal
            let signalLength = Int(hopSize * 4) // 4 frames
            var detectedAccelerate = 0.0
            var detectedZen = 0.0
            
            for i in 0..<signalLength {
                let sample = Float(sin(2.0 * .pi * testFreq * Double(i) / sampleRate))
                
                var pitch: Double = 0
                var amplitude: Double = 0
                
                accelerateTracker.compute(bufferValue: sample, pitch: &pitch, amplitude: &amplitude)
                if pitch > 0 {
                    detectedAccelerate = pitch
                }
                
                zenTracker.compute(bufferValue: sample, pitch: &pitch, amplitude: &amplitude)
                if pitch > 0 {
                    detectedZen = pitch
                }
            }
            
            let accelerateError = abs(detectedAccelerate - testFreq) / testFreq * 100
            let zenError = abs(detectedZen - testFreq) / testFreq * 100
            
            print(String(format: "%.1f Hz: Acc=%.1f (%.1f%%) Zen=%.1f (%.1f%%)", 
                         testFreq, detectedAccelerate, accelerateError, detectedZen, zenError))
        }
        
        // Reset to default
        FFTConfiguration.defaultImplementation = .accelerate
    }
    
    /// Run comprehensive performance benchmarks
    private static func runPerformanceBenchmarks() {
        print("\n⚡ Performance Benchmarks")
        print("-------------------------")
        
        FFTBenchmark.runBenchmark()
        
        // Test real-world performance with ZenPTrack
        print("🎯 Real-world ZenPTrack Performance")
        print("-----------------------------------")
        
        let sampleRate = 44100.0
        let hopSize = 2048.0
        let iterations = 1000
        
        // Test Accelerate implementation
        FFTConfiguration.defaultImplementation = .accelerate
        var accelerateTracker = ZenPTrack(sampleRate: sampleRate, hopSize: hopSize, peakCount: 20)
        
        let accelerateStart = CFAbsoluteTimeGetCurrent()
        for i in 0..<iterations {
            let sample = Float(sin(2.0 * .pi * 440.0 * Double(i) / sampleRate))
            var pitch: Double = 0
            var amplitude: Double = 0
            accelerateTracker.compute(bufferValue: sample, pitch: &pitch, amplitude: &amplitude)
        }
        let accelerateTime = CFAbsoluteTimeGetCurrent() - accelerateStart
        
        // Test ZenFFT implementation
        FFTConfiguration.defaultImplementation = .zen
        var zenTracker = ZenPTrack(sampleRate: sampleRate, hopSize: hopSize, peakCount: 20)
        
        let zenStart = CFAbsoluteTimeGetCurrent()
        for i in 0..<iterations {
            let sample = Float(sin(2.0 * .pi * 440.0 * Double(i) / sampleRate))
            var pitch: Double = 0
            var amplitude: Double = 0
            zenTracker.compute(bufferValue: sample, pitch: &pitch, amplitude: &amplitude)
        }
        let zenTime = CFAbsoluteTimeGetCurrent() - zenStart
        
        let speedup = zenTime / accelerateTime
        
        print(String(format: "Accelerate ZenPTrack: %.2f ms", accelerateTime * 1000))
        print(String(format: "ZenFFT ZenPTrack:     %.2f ms", zenTime * 1000))
        print(String(format: "Overall Speedup:      %.1fx", speedup))
        
        // Reset to default
        FFTConfiguration.defaultImplementation = .accelerate
    }
    
    /// Helper function to find peak frequency in FFT buffer
    private static func findPeakFrequency(fftBuffer: [Float], sampleRate: Double) -> Double {
        let halfSize = fftBuffer.count / 2
        var maxMagnitude: Float = 0
        var maxIndex = 0
        
        // Find peak in magnitude spectrum
        for i in 1..<halfSize {
            let real = fftBuffer[i * 2]
            let imag = fftBuffer[i * 2 + 1]
            let magnitude = sqrt(real * real + imag * imag)
            
            if magnitude > maxMagnitude {
                maxMagnitude = magnitude
                maxIndex = i
            }
        }
        
        // Convert bin index to frequency
        return Double(maxIndex) * sampleRate / Double(fftBuffer.count)
    }
}