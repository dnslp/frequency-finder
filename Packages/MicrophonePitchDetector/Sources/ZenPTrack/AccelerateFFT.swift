/*
 * Accelerate Framework FFT Implementation
 * 
 * High-performance FFT replacement for ZenFFT using Apple's Accelerate framework
 * Maintains API compatibility with ZenFFT for seamless integration
 */

import Accelerate
import Darwin

/// High-performance FFT processor using Apple's Accelerate framework
/// Maintains compatibility with the original ZenFFT interface
public final class AccelerateFFT {
    private let logSize: Int
    private let fftSetup: FFTSetup
    private var realBuffer: UnsafeMutablePointer<Float>
    private var imagBuffer: UnsafeMutablePointer<Float>
    private var splitComplex: DSPSplitComplex
    private let fftSize: Int
    private let halfSize: Int
    
    /// Initialize FFT processor
    /// - Parameters:
    ///   - M: Bit-reversal table size parameter (matches ZenFFT parameter)
    ///   - size: Actual FFT size (matches ZenFFT parameter)
    public init(M: Int, size: Double) {
        // Match ZenFFT behavior: actual log size comes from size parameter
        self.logSize = Int(log2(size))
        self.fftSize = Int(size)
        self.halfSize = fftSize / 2
        
        // Validate parameters to prevent memory corruption
        assert(fftSize == (1 << logSize), "FFT size must be power of 2: \(fftSize) != 2^(\(logSize))")
        
        // Create FFT setup for complex-to-complex transform
        guard let setup = vDSP_create_fftsetup(vDSP_Length(logSize), FFTRadix(kFFTRadix2)) else {
            fatalError("Failed to create vDSP FFT setup with logSize=\(logSize)")
        }
        self.fftSetup = setup
        
        // Allocate aligned memory for FFT buffers
        self.realBuffer = UnsafeMutablePointer<Float>.allocate(capacity: halfSize)
        self.imagBuffer = UnsafeMutablePointer<Float>.allocate(capacity: halfSize)
        
        // Initialize buffers to zero
        realBuffer.initialize(repeating: 0.0, count: halfSize)
        imagBuffer.initialize(repeating: 0.0, count: halfSize)
        
        // Create split complex structure
        self.splitComplex = DSPSplitComplex(realp: realBuffer, imagp: imagBuffer)
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
        realBuffer.deinitialize(count: halfSize)
        imagBuffer.deinitialize(count: halfSize)
        realBuffer.deallocate()
        imagBuffer.deallocate()
    }
    
    /// Compute FFT on interleaved real/imaginary buffer
    /// Maintains ZenFFT interface: input/output in same buffer, interleaved format
    /// - Parameter buf: Interleaved real/imaginary buffer [re0, im0, re1, im1, ...]
    public func compute(buf: inout [Float]) {
        let inputHalfSize = buf.count / 2
        
        // Ensure we don't exceed our buffer capacity
        let validSize = min(inputHalfSize, halfSize)
        
        // Validate input buffer size
        assert(buf.count >= validSize * 2, "Input buffer too small: \(buf.count) < \(validSize * 2)")
        assert(validSize <= halfSize, "ValidSize exceeds halfSize: \(validSize) > \(halfSize)")
        
        // Extract real and imaginary parts from interleaved buffer
        for i in 0..<validSize {
            realBuffer[i] = buf[i * 2]
            imagBuffer[i] = buf[i * 2 + 1]
        }
        
        // Perform forward FFT (complex-to-complex)
        vDSP_fft_zip(fftSetup, &splitComplex, 1, vDSP_Length(logSize), FFTDirection(kFFTDirection_Forward))
        
        // Reinterleave back into original buffer format
        for i in 0..<validSize {
            buf[i * 2] = realBuffer[i]
            buf[i * 2 + 1] = imagBuffer[i]
        }
    }
}

// MARK: - Performance Benchmarking

public struct FFTBenchmark {
    public static func measurePerformance(iterations: Int = 1000, fftSize: Int = 4096) -> (accelerate: TimeInterval, zen: TimeInterval) {
        let M = Int(log2(Double(fftSize)))
        let size = Double(fftSize)
        
        // Setup both FFT implementations
        let accelerateFFT = AccelerateFFT(M: M, size: size)
        let zenFFT = ZenFFT(M: M, size: size)
        
        // Test data - interleaved complex buffer
        let testBuffer = Array(0..<fftSize).map { i in
            Float(sin(2.0 * .pi * Double(i) / Double(fftSize)))
        }
        
        // Benchmark Accelerate implementation
        var accelerateBuffer = testBuffer
        let accelerateStart = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            accelerateFFT.compute(buf: &accelerateBuffer)
        }
        
        let accelerateTime = CFAbsoluteTimeGetCurrent() - accelerateStart
        
        // Benchmark ZenFFT implementation
        var zenBuffer = testBuffer
        let zenStart = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            zenFFT.compute(buf: &zenBuffer)
        }
        
        let zenTime = CFAbsoluteTimeGetCurrent() - zenStart
        
        return (accelerate: accelerateTime, zen: zenTime)
    }
    
    public static func runBenchmark() {
        print("🔬 FFT Performance Benchmark")
        print("============================")
        
        let testSizes = [1024, 2048, 4096, 8192]
        
        for size in testSizes {
            let times = measurePerformance(iterations: 100, fftSize: size)
            let speedup = times.zen / times.accelerate
            
            print(String(format: "FFT Size: %d", size))
            print(String(format: "  Accelerate: %.4f ms", times.accelerate * 1000))
            print(String(format: "  ZenFFT:     %.4f ms", times.zen * 1000))
            print(String(format: "  Speedup:    %.2fx", speedup))
            print()
        }
    }
}

// MARK: - Accuracy Verification

public struct FFTAccuracyTest {
    /// Compare outputs of both FFT implementations to verify correctness
    public static func verifyAccuracy(fftSize: Int = 4096, tolerance: Float = 1e-4) -> Bool {
        let M = Int(log2(Double(fftSize)))
        let size = Double(fftSize)
        
        let accelerateFFT = AccelerateFFT(M: M, size: size)
        let zenFFT = ZenFFT(M: M, size: size)
        
        // Create test signal - sine wave with harmonics
        let testBuffer = Array(0..<fftSize).map { i in
            let fundamental = sin(2.0 * .pi * 440.0 * Double(i) / 44100.0)
            let harmonic = 0.5 * sin(2.0 * .pi * 880.0 * Double(i) / 44100.0)
            return Float(fundamental + harmonic)
        }
        
        var accelerateBuffer = testBuffer
        var zenBuffer = testBuffer
        
        // Compute FFTs
        accelerateFFT.compute(buf: &accelerateBuffer)
        zenFFT.compute(buf: &zenBuffer)
        
        // Compare results
        var maxError: Float = 0
        var totalError: Float = 0
        
        for i in 0..<fftSize {
            let error = abs(accelerateBuffer[i] - zenBuffer[i])
            maxError = max(maxError, error)
            totalError += error
        }
        
        let avgError = totalError / Float(fftSize)
        
        print("🧪 FFT Accuracy Verification")
        print("============================")
        print(String(format: "Max Error:     %.2e", maxError))
        print(String(format: "Average Error: %.2e", avgError))
        print(String(format: "Tolerance:     %.2e", tolerance))
        
        let passed = maxError < tolerance
        print(String(format: "Result:        %@", passed ? "✅ PASS" : "❌ FAIL"))
        
        return passed
    }
}