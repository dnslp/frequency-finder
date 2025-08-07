import SwiftUI
import WebKit

struct WebReadingPassageSessionView: View {
    @StateObject private var viewModel: WebReadingPassageViewModel
    @State private var isRecordButtonPressed = false
    
    private let webURL = URL(string: "https://dnslp.github.io/reading-passage/")!

    init(profileManager: UserProfileManager) {
        _viewModel = StateObject(wrappedValue: WebReadingPassageViewModel(profileManager: profileManager))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Web content area
                    WebViewWithNavigation(url: webURL, viewModel: viewModel)
                        .frame(maxHeight: .infinity)
                    
                    // Recording UI overlay
                    VStack(spacing: 16) {
                        if viewModel.isRecording {
                            RecordingStatusCard(viewModel: viewModel)
                        } else if viewModel.showResult {
                            WebResultsCard(viewModel: viewModel)
                                .onAppear { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                        }
                        
                        if viewModel.promptRerecord {
                            Text("Recording too short or invalid. Please try again.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 0)
                    
                    // Recording controls at bottom
                    WebRecordingControls(viewModel: viewModel, isPressed: $isRecordButtonPressed)
                        .padding()
                }
                
                // Soft blue glow border when recording
                if viewModel.isRecording {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.blue.opacity(0.8), lineWidth: 10)
                        .blur(radius: 5)
                        .allowsHitTesting(false)
                }
            }
//            .navigationTitle("Web Reading Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("🔥 \(viewModel.profileManager.currentProfile.analytics.streakDays) Day Streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.orange)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SessionHistoryView(profileManager: viewModel.profileManager)) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .onDisappear { viewModel.invalidateTimers() }
            .task { viewModel.activatePitchDetector() }
        }
    }
}

// MARK: - Enhanced WebView with Navigation Tracking
struct WebViewWithNavigation: UIViewRepresentable {
    let url: URL
    let viewModel: WebReadingPassageViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = viewModel
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

// MARK: - Recording Status Card
struct RecordingStatusCard: View {
    @ObservedObject var viewModel: WebReadingPassageViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🎙️ Recording...")
                .foregroundColor(.green)
            Text("⏱ Elapsed: \(viewModel.formatTime(viewModel.elapsedTime))")
            GradientProgressBar(progress: min(viewModel.elapsedTime / viewModel.minSessionDuration, 1.0))
                .frame(height: 8)
                .padding(.horizontal)
            SineWaveView(frequency: max(0.5, min(viewModel.smoothedPitch / 200, 6.0)),
                         amplitude: 0.6,
                         phase: viewModel.wavePhase)
                .transition(.opacity)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Web Results Card  
struct WebResultsCard: View {
    @ObservedObject var viewModel: WebReadingPassageViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Session Complete 🎉").font(.title3.weight(.semibold))
            Text("URL: \(viewModel.currentURL)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if let f0 = viewModel.calculatedF0,
               let stdDev = viewModel.pitchStdDev,
               let minP = viewModel.pitchMin,
               let maxP = viewModel.pitchMax {
                VStack(spacing: 8) {
                    Text("Average Pitch (f₀): \(f0, specifier: "%.1f") Hz")
                    Divider()
                    Text("Pitch Stability: \(stdDev, specifier: "%.1f") Hz")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Divider()
                    Text("Pitch Range: \(minP, specifier: "%.1f") - \(maxP, specifier: "%.1f") Hz")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Web Recording Controls
struct WebRecordingControls: View {
    @ObservedObject var viewModel: WebReadingPassageViewModel
    @Binding var isPressed: Bool
    
    var body: some View {
        VStack(spacing: 16) {
//            HStack(spacing: 16) {
//                Picker("Font", selection: $viewModel.selectedFont) {
//                    ForEach(viewModel.availableFonts, id: \.self) { font in
//                        Text(font).tag(font)
//                    }
//                }
//                .pickerStyle(.menu)
//                .disabled(viewModel.isRecording)
//
//                Stepper(value: $viewModel.fontSize, in: 12...28) {
//                    Text("Size: \(Int(viewModel.fontSize))")
//                }
//                .disabled(viewModel.isRecording)
//            }
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isPressed.toggle()
                if viewModel.isRecording { viewModel.stopRecording() } else { viewModel.startRecording() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed.toggle() }
            }) {
                Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRecording ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isPressed)
            }
            .frame(minHeight: 44)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
struct WebReadingPassageSessionView_Previews: PreviewProvider {
    static var previews: some View {
        WebReadingPassageSessionView(profileManager: UserProfileManager())
    }
}
