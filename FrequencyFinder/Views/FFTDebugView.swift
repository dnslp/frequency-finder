//
//  FFTDebugView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 8/6/25.
//


import SwiftUI
import ZenPTrack
import MicrophonePitchDetector

struct FFTDebugView: View {
    @State private var currentImplementation = FFTConfiguration.defaultImplementation
    @State private var showPerformanceData = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🧪 FFT Implementation Testing")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Implementation:")
                    .font(.headline)
                
                Picker("FFT Implementation", selection: $currentImplementation) {
                    Text("🚀 Accelerate Framework (New)").tag(FFTImplementation.accelerate)
                    Text("⚡ ZenFFT (Original)").tag(FFTImplementation.zen)
                }
                .pickerStyle(.segmented)
                .onChange(of: currentImplementation) { implementation in
                    FFTConfiguration.defaultImplementation = implementation
                    print("🔄 Switched to FFT implementation: \(implementation == .accelerate ? "Accelerate" : "ZenFFT")")
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How to Test:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. Switch between implementations above")
                    Text("2. Record a reading passage")
                    Text("3. Compare pitch detection accuracy")
                    Text("4. Notice any performance differences")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Button("Run Performance Benchmark") {
                showPerformanceData = true
                runPerformanceBenchmark()
            }
            .buttonStyle(.borderedProminent)
            
            if showPerformanceData {
                Text("Check console for benchmark results")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func runPerformanceBenchmark() {
        showPerformanceData = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Simple performance test without complex dependencies
            let startAccelerate = CFAbsoluteTimeGetCurrent()
            
            // Test Accelerate implementation
            let fftAccelerate = AccelerateFFT(M: 11, size: 1024.0)
            var testDataAccelerate = Array(0..<2048).map { i in
                Float(sin(2.0 * .pi * Double(i) / 2048.0))
            }
            
            for _ in 0..<100 {
                fftAccelerate.compute(buf: &testDataAccelerate)
            }
            let accelerateTime = CFAbsoluteTimeGetCurrent() - startAccelerate
            
            // Test ZenFFT implementation  
            let startZen = CFAbsoluteTimeGetCurrent()
            let fftZen = ZenFFT(M: 11, size: 1024.0)
            var testDataZen = Array(0..<2048).map { i in
                Float(sin(2.0 * .pi * Double(i) / 2048.0))
            }
            
            for _ in 0..<100 {
                fftZen.compute(buf: &testDataZen)
            }
            let zenTime = CFAbsoluteTimeGetCurrent() - startZen
            
            let speedup = zenTime / accelerateTime
            
            DispatchQueue.main.async {
                print("🔬 FFT Performance Benchmark Results")
                print("====================================")
                print(String(format: "Accelerate: %.2f ms", accelerateTime * 1000))
                print(String(format: "ZenFFT:     %.2f ms", zenTime * 1000))
                print(String(format: "Speedup:    %.1fx", speedup))
                print(String(format: "Winner:     %@", speedup > 1 ? "🚀 Accelerate" : "⚡ ZenFFT"))
            }
        }
    }
}

#Preview {
    FFTDebugView()
}
