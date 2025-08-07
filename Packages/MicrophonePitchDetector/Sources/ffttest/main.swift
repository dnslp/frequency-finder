/*
 * FFT Test Runner
 *
 * Simple command-line tool to test and benchmark the FFT implementations
 */

import Foundation
import ZenPTrack

print("🚀 FrequencyFinder FFT Optimization Test")
print("========================================")

// First run a minimal test
print("🧪 Minimal FFT Test")
print("==================")

do {
    // Test basic FFT creation and usage
    print("Creating FFT instances...")
    
    let M = 11  // 2^11 = 2048
    let size = 1024.0
    
    print("Testing ZenFFT...")
    let zenFFT = ZenFFT(M: M, size: size)
    
    print("Testing AccelerateFFT...")
    let accelerateFFT = AccelerateFFT(M: M, size: size)
    
    // Create simple test data
    var testData: [Float] = []
    for i in 0..<Int(size * 2) {
        if i % 2 == 0 {
            // Real part - simple sine wave
            testData.append(Float(sin(2.0 * .pi * Double(i/2) / size)))
        } else {
            // Imaginary part - zero
            testData.append(0.0)
        }
    }
    
    var zenData = testData
    var accelerateData = testData
    
    print("Running ZenFFT...")
    zenFFT.compute(buf: &zenData)
    
    print("Running AccelerateFFT...")
    accelerateFFT.compute(buf: &accelerateData)
    
    // Check for obvious problems
    let zenMax = zenData.max() ?? 0
    let accelerateMax = accelerateData.max() ?? 0
    
    print("ZenFFT max value: \(zenMax)")
    print("AccelerateFFT max value: \(accelerateMax)")
    
    print("✅ Basic FFT test complete")
    
    // If basic test passes, run comprehensive tests
    if zenMax.isFinite && accelerateMax.isFinite && zenMax > 0 && accelerateMax > 0 {
        print("\n✅ Basic FFT functionality working!")
        
        // Simple performance test
        print("\n⚡ Quick Performance Test")
        print("========================")
        
        let iterations = 100
        var zenTestData = testData
        var accelerateTestData = testData
        
        let zenStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            zenFFT.compute(buf: &zenTestData)
        }
        let zenTime = CFAbsoluteTimeGetCurrent() - zenStart
        
        let accelerateStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            accelerateFFT.compute(buf: &accelerateTestData)
        }
        let accelerateTime = CFAbsoluteTimeGetCurrent() - accelerateStart
        
        let speedup = zenTime / accelerateTime
        
        print(String(format: "ZenFFT time:      %.2f ms", zenTime * 1000))
        print(String(format: "Accelerate time:  %.2f ms", accelerateTime * 1000))
        print(String(format: "Speedup:          %.1fx", speedup))
        
        if speedup > 1.0 {
            print("🚀 Accelerate is faster!")
        } else {
            print("⚠️ ZenFFT appears faster (unexpected)")
        }
    } else {
        print("❌ Basic test failed - skipping performance tests")
        print("ZenFFT max: \(zenMax), AccelerateFFT max: \(accelerateMax)")
    }
    
} catch {
    print("❌ Error: \(error)")
}

print("\n🎯 Test Complete")
print("================")

#if DEBUG
print("📊 The app will use Apple's Accelerate framework for improved performance")
#endif