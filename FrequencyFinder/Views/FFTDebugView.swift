import SwiftUI
import ZenPTrack

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
        DispatchQueue.global(qos: .userInitiated).async {
            let results = FFTProcessor.performanceComparison()
            
            DispatchQueue.main.async {
                print("🔬 FFT Performance Benchmark Results")
                print("====================================")
                print(String(format: "Accelerate: %.2f ms", results.accelerate * 1000))
                print(String(format: "ZenFFT:     %.2f ms", results.zen * 1000))
                print(String(format: "Speedup:    %.1fx", results.speedup))
                print(String(format: "Winner:     %@", results.speedup > 1 ? "🚀 Accelerate" : "⚡ ZenFFT"))
            }
        }
    }
}

#Preview {
    FFTDebugView()
}