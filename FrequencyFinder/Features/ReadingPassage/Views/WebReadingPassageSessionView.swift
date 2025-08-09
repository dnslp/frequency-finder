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
                    // Web content area with loading overlay
                    ZStack {
                        WebViewWithNavigation(url: webURL, viewModel: viewModel)
                            .frame(maxHeight: .infinity)
                            .opacity(viewModel.isWebViewLoading ? 0.3 : 1.0)
                        
                        if viewModel.isWebViewLoading {
                            WebLoadingView()
                        }
                    }
                    
                    // Results and error overlay - minimal space usage
                    VStack(spacing: 12) {
                        if viewModel.showResult {
                            DismissibleResultsCard(viewModel: viewModel)
                                .onAppear { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                        }
                        
                        if viewModel.promptRerecord {
                            Text("Recording too short or invalid. Please try again.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recording controls at bottom - only show if passageId exists
                    if viewModel.hasPassageId {
                        CardView {
                            WebRecordingControlsView(viewModel: viewModel, isPressed: $isRecordButtonPressed)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }
                }
                .animation(.easeInOut(duration: 0.6), value: viewModel.hasPassageId)
                
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
            .onAppear {
                print("📱 DEBUG: WebReadingPassageSessionView appeared - isWebViewLoading: \(viewModel.isWebViewLoading)")
                // Fallback: Clear loading state after 5 seconds if it hasn't cleared
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if viewModel.isWebViewLoading {
                        print("⚠️ DEBUG: Clearing loading state after timeout")
                        viewModel.isWebViewLoading = false
                    }
                }
            }
        }
    }
}


// MARK: - Enhanced WebView with Navigation Tracking
struct WebViewWithNavigation: UIViewRepresentable {
    let url: URL
    let viewModel: WebReadingPassageViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = viewModel.navigationDelegate
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator {
        let viewModel: WebReadingPassageViewModel
        
        init(viewModel: WebReadingPassageViewModel) {
            self.viewModel = viewModel
        }
        
        func webViewDidFinishLoad(_ webView: WKWebView) {
            // Start URL monitoring after the web view loads
            viewModel.startURLMonitoring(webView: webView)
        }
    }
}


// MARK: - Dismissible Results Card
struct DismissibleResultsCard: View {
    @ObservedObject var viewModel: WebReadingPassageViewModel
    
    var body: some View {
        CardView {
            VStack(spacing: 16) {
                // Header with close button
                HStack {
                    Text("Session Complete 🎉")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) {
                            viewModel.resetResults()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                if let passageId = viewModel.passageId {
                    Text("Passage: \(passageId)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let f0 = viewModel.calculatedF0,
                   let stdDev = viewModel.pitchStdDev,
                   let minP = viewModel.pitchMin,
                   let maxP = viewModel.pitchMax {
                    VStack(spacing: 8) {
                        Text("Average Pitch (f₀): \(f0, specifier: "%.1f") Hz")
                            .font(.body)
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
                
                // Record again button
//                Button("Record Again") {
//                    withAnimation(.easeInOut) {
//                        viewModel.resetResults()
//                    }
//                }
//                .font(.headline)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(Color.accentColor)
//                .foregroundColor(.white)
//                .cornerRadius(12)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}


// MARK: - Compact Recording Controls
struct WebRecordingControlsView: View {
    @ObservedObject var viewModel: WebReadingPassageViewModel
    @Binding var isPressed: Bool
    @State private var buttonScale: CGFloat = 0.8
    
    var body: some View {
        HStack(spacing: 12) {
            if viewModel.isRecording {
                // Left side: Timer with animated recording indicator
                HStack(spacing: 8) {
                    // Animated recording dot
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(0.3)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isRecording)
                    
                    Text("⏱ \(viewModel.formatTime(viewModel.elapsedTime))")
                        .font(.headline.monospacedDigit())
                        .foregroundColor(.primary)
                        .onAppear {
                            print("🕐 DEBUG: Timer display appeared - elapsedTime: \(viewModel.elapsedTime)")
                        }
                    
                    // Pitch detection indicator
                    if viewModel.smoothedPitch > 50 {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .opacity(0.8)
                            .scaleEffect(min(viewModel.smoothedPitch / 200, 2.0))
                            .animation(.easeOut(duration: 0.1), value: viewModel.smoothedPitch)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 2, height: 6)
                            .opacity(0.3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onReceive(viewModel.objectWillChange) { _ in
                    print("🔄 DEBUG: Timer received update - elapsedTime: \(viewModel.elapsedTime), pitch: \(viewModel.smoothedPitch)")
                }
                
                // Right side: Compact stop button
                Button(action: stopRecording) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.subheadline)
                        Text("Stop")
                            .font(.headline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                }
            } else {
                // Full-width start recording button
                Button(action: startRecording) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                        Text("Start Recording")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                }
                .scaleEffect(buttonScale)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                        buttonScale = 1.0
                    }
                }
            }
        }
        .frame(minHeight: 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isRecording)
    }
    
    private func startRecording() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isPressed.toggle()
        viewModel.startRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed.toggle() }
    }
    
    private func stopRecording() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isPressed.toggle()
        viewModel.stopRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed.toggle() }
    }
}

// MARK: - Debug Info Card
struct DebugInfoCard: View {
    @ObservedObject var viewModel: WebReadingPassageViewModel
    @State private var refreshCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🐛 DEBUG INFO")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                Spacer()
                Text("Refresh: \(refreshCount)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Text(viewModel.debugInfo)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .onAppear {
                    print("📱 DEBUG: DebugInfoCard appeared with info: \(viewModel.debugInfo)")
                }
            
            Text("hasPassageId: \(viewModel.hasPassageId ? "✅" : "❌")")
                .font(.caption)
                .foregroundColor(viewModel.hasPassageId ? .green : .red)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .onReceive(viewModel.objectWillChange) { _ in
            refreshCount += 1
            print("🔄 DEBUG: DebugInfoCard refreshed (\(refreshCount)) - hasPassageId=\(viewModel.hasPassageId)")
        }
    }
}

// MARK: - Web Loading Animation
struct WebLoadingView: View {
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated logo/icon
            Image(systemName: "globe")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.accentColor)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                .onAppear {
                    pulseScale = 1.2
                }
            
            VStack(spacing: 12) {
                Text("Loading Reading Passages...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Animated progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationOffset == CGFloat(index) ? 1.5 : 0.8)
                            .animation(.easeInOut(duration: 0.6).repeatForever(), value: animationOffset)
                    }
                }
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
                        withAnimation {
                            animationOffset = animationOffset >= 2 ? 0 : animationOffset + 1
                        }
                    }
                }
                
                Text("Connecting to server...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Mock Recording Controls for Preview
struct MockWebRecordingControlsView: View {
    let isRecording: Bool
    @State private var isPressed = false
    @State private var buttonScale: CGFloat = 0.8
    
    var body: some View {
        HStack(spacing: 12) {
            if isRecording {
                // Left side: Timer with animated recording indicator
                HStack(spacing: 8) {
                    // Animated recording dot
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(0.3)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                    
                    Text("⏱ 0:12")
                        .font(.headline.monospacedDigit())
                        .foregroundColor(.primary)
                    
                    // Pitch detection indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .opacity(0.8)
                        .scaleEffect(1.2)
                        .animation(.easeOut(duration: 0.1), value: UUID())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side: Compact stop button
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.subheadline)
                        Text("Stop")
                            .font(.headline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                }
            } else {
                // Full-width start recording button
                Button(action: { isPressed.toggle(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed.toggle() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                        Text("Start Recording")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                }
                .scaleEffect(buttonScale)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                        buttonScale = 1.0
                    }
                }
            }
        }
        .frame(minHeight: 40)
    }
}

// MARK: - Preview
struct WebReadingPassageSessionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            // Simulated web content area
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    Text("📱 Web Reading Passage Content\n(Simulated)")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                )
            
            // Simulated recording controls
            CardView {
                MockWebRecordingControlsView(isRecording: false)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .previewDisplayName("Start Recording Button")
        
        VStack(spacing: 0) {
            // Simulated web content area
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    Text("📱 Web Reading Passage Content\n(Recording...)")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                )
            
            // Simulated recording controls - recording state
            CardView {
                MockWebRecordingControlsView(isRecording: true)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .previewDisplayName("Recording State")
    }
}
