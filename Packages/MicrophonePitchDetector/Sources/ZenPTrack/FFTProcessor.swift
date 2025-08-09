/*
 * FFT Processor - Unified Interface
 *
 * Provides a unified interface that can switch between ZenFFT and AccelerateFFT implementations
 * Allows for easy A/B testing and gradual migration
 */

import Foundation

/// FFT Implementation type selector
public enum FFTImplementation {
    case zen        // Original ZenFFT implementation
    case accelerate // New Accelerate framework implementation
}

/// Unified FFT processor that can use either ZenFFT or AccelerateFFT
public final class FFTProcessor {
    private let implementation: FFTImplementation
    private let zenFFT: ZenFFT?
    private let accelerateFFT: AccelerateFFT?
    
    /// Current implementation being used (for debugging/monitoring)
    public var currentImplementation: FFTImplementation { implementation }
    
    /// Initialize with specified FFT implementation
    /// - Parameters:
    ///   - M: Log2 of FFT size
    ///   - size: FFT size 
    ///   - implementation: Which FFT implementation to use
    public init(M: Int, size: Double, implementation: FFTImplementation = .accelerate) {
        self.implementation = implementation
        
        switch implementation {
        case .zen:
            self.zenFFT = ZenFFT(M: M, size: size)
            self.accelerateFFT = nil
            
        case .accelerate:
            self.zenFFT = nil
            self.accelerateFFT = AccelerateFFT(M: M, size: size)
        }
    }
    
    /// Compute FFT using the selected implementation
    /// - Parameter buf: Interleaved complex buffer to transform in-place
    public func compute(buf: inout [Float]) {
        switch implementation {
        case .zen:
            zenFFT?.compute(buf: &buf)
            
        case .accelerate:
            accelerateFFT?.compute(buf: &buf)
        }
    }
    
    /// Run performance comparison between implementations
    /// - Returns: Performance metrics for both implementations
    public static func performanceComparison() -> (accelerate: TimeInterval, zen: TimeInterval, speedup: Double) {
        let results = FFTBenchmark.measurePerformance(iterations: 1000, fftSize: 4096)
        let speedup = results.zen / results.accelerate
        
        return (accelerate: results.accelerate, zen: results.zen, speedup: speedup)
    }
}

// MARK: - Global Configuration

/// Global configuration for FFT implementation choice
public struct FFTConfiguration {
    /// Default FFT implementation to use throughout the app
    /// Change this to .zen to use the original implementation for comparison
    public static var defaultImplementation: FFTImplementation = .accelerate
    
    /// Enable performance monitoring
    public static var enablePerformanceLogging = false
    
    /// Log performance comparison on first use
    public static var logInitialBenchmark = false
    
    /// Performance monitoring helper
    public static func logPerformanceIfNeeded() {
        guard logInitialBenchmark && enablePerformanceLogging else { return }
        
        logInitialBenchmark = false
        
        print("🚀 FFT Implementation: \(defaultImplementation == .accelerate ? "Accelerate" : "ZenFFT")")
    }
}