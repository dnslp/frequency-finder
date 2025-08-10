import SwiftUI
import Combine
@preconcurrency import WebKit

class WebReadingPassageViewModel: ObservableObject {
    @Published var fontSize: CGFloat = 16
    @Published var selectedFont: String = "System"
    
    @Published var isRecording = false
    @Published var showResult = false
    @Published var promptRerecord = false
    @Published var calculatedF0: Double?
    @Published var pitchStdDev: Double?
    @Published var pitchMin: Double?
    @Published var pitchMax: Double?
    @Published var elapsedTime: TimeInterval = 0 {
        didSet {
            print("⏱️ DEBUG: elapsedTime updated to \(elapsedTime)")
        }
    }
    @Published var smoothedPitch: Double = 0 {
        didSet {
            print("🎵 DEBUG: smoothedPitch updated to \(smoothedPitch)")
        }
    }
    @Published var wavePhase = 0.0
    @Published var currentURL: String = ""
    @Published var passageId: String? = nil
    @Published var chunkId: String? = nil
    @Published var hasPassageId: Bool = false {
        didSet {
            print("📱 DEBUG: hasPassageId changed from \(oldValue) to \(hasPassageId)")
        }
    }
    @Published var debugInfo: String = "No URL loaded yet" {
        didSet {
            print("📝 DEBUG: debugInfo updated")
        }
    }
    @Published var isWebViewLoading: Bool = false {
        didSet {
            print("🌐 DEBUG: isWebViewLoading changed from \(oldValue) to \(isWebViewLoading)")
        }
    }
    
    // Debug flag - set to true to always show recording button for testing
    let alwaysShowRecordingButton = false
    
    private var audioManager = AudioManager()
    private var pitchSamples: [Double] = []
    private var startTime: Date?
    private var duration: TimeInterval = 0
    
    private var waveTimer: Timer?
    private var pitchTimer: Timer?
    private var elapsedTimer: Timer?
    private var urlMonitorTimer: Timer?
    
    let availableFonts = ["System", "Times New Roman", "Georgia", "Helvetica", "Verdana", "Courier New"]
    let minSessionDuration: TimeInterval = 6.0
    let minSampleCount: Int = 12
    private let pitchSmoothingFactor: Double = 0.1
    
    @ObservedObject var profileManager: UserProfileManager
    
    // Navigation delegate for WebView
    lazy var navigationDelegate = WebNavigationDelegate(viewModel: self)
    
    init(profileManager: UserProfileManager) {
        self.profileManager = profileManager
    }
    
    func activatePitchDetector() {
        print("🎤 DEBUG: Attempting to activate pitch detector...")
        audioManager.start()
        print("✅ DEBUG: Pitch detector activated successfully")
    }
    
    func invalidateTimers() {
        waveTimer?.invalidate()
        pitchTimer?.invalidate()
        elapsedTimer?.invalidate()
        urlMonitorTimer?.invalidate()
        waveTimer = nil
        pitchTimer = nil
        elapsedTimer = nil
        urlMonitorTimer = nil
    }
    
    func startURLMonitoring(webView: WKWebView) {
        print("🔍 DEBUG: Starting URL monitoring timer")
        urlMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            webView.evaluateJavaScript("window.location.href") { [weak self] result, error in
                if let urlString = result as? String {
                    DispatchQueue.main.async {
                        if self?.currentURL != urlString {
                            print("🔄 DEBUG: URL changed via JavaScript: \(urlString)")
                            self?.currentURL = urlString
                            self?.parseURLParameters(from: urlString)
                        }
                    }
                }
            }
        }
    }
    
    func startRecording() {
        print("🎙️ DEBUG: Starting recording process...")
        pitchSamples.removeAll()
        startTime = Date()
        elapsedTime = 0
        isRecording = true
        promptRerecord = false
        showResult = false
        
        // Start audio processing if not already running
        if !audioManager.isListening {
            audioManager.start()
            print("🎙️ DEBUG: Started AudioManager")
        }
        
        print("🎙️ DEBUG: Recording state set to true, starting timers...")
        
        wavePhase = 0
        waveTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.wavePhase += 0.15
        }
        
        pitchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let pitch = Double(self.audioManager.frequency)
            print("🎵 DEBUG: Raw pitch detected: \(pitch)")
            
            if pitch > 55 && pitch < 500 {
                self.pitchSamples.append(pitch)
                print("✅ DEBUG: Valid pitch added to samples: \(pitch) (total samples: \(self.pitchSamples.count))")
                self.smoothedPitch = self.smoothedPitch * (1 - self.pitchSmoothingFactor) + pitch * self.pitchSmoothingFactor
            } else {
                print("❌ DEBUG: Invalid pitch rejected: \(pitch)")
            }
        }
        
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if let start = self?.startTime {
                self?.elapsedTime = Date().timeIntervalSince(start)
            }
        }
        
        print("🎙️ DEBUG: All timers started, isRecording: \(isRecording)")
    }
    
    func stopRecording() {
        print("🛑 DEBUG: Stopping recording...")
        isRecording = false
        invalidateTimers()
        duration = Date().timeIntervalSince(startTime ?? Date())
        
        // Keep audio manager running for potential future recordings
        // audioManager.stop()
        
        print("🛑 DEBUG: Recording stopped - Duration: \(duration)s, Samples collected: \(pitchSamples.count)")
        print("🛑 DEBUG: Minimum duration required: \(minSessionDuration)s, Minimum samples: \(minSampleCount)")
        
        if pitchSamples.isEmpty {
            print("❌ DEBUG: No pitch samples collected at all!")
        } else {
            print("✅ DEBUG: Sample range: \(pitchSamples.min() ?? 0) - \(pitchSamples.max() ?? 0) Hz")
        }
        
        guard duration >= minSessionDuration, pitchSamples.count >= minSampleCount else {
            promptRerecord = true
            print("❗️ DEBUG: Not enough valid data: duration = \(duration), samples = \(pitchSamples.count)")
            return
        }
        
        let statsCalculator = StatisticsCalculator()
        let filteredSamples = statsCalculator.removeOutliers(from: pitchSamples)
        
        if let stats = statsCalculator.calculateStatistics(for: filteredSamples) {
            calculatedF0 = stats.median
            pitchMin = stats.min
            pitchMax = stats.max
            pitchStdDev = stats.stdDev
            showResult = true
            
            let notesString = buildNotesString()
            profileManager.addSession(
                type: .readingAnalysis,
                pitchSamples: pitchSamples,
                duration: duration,
                notes: notesString
            )
        } else {
            promptRerecord = true
        }
    }
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    func resetResults() {
        showResult = false
        promptRerecord = false
        calculatedF0 = nil
        pitchStdDev = nil
        pitchMin = nil
        pitchMax = nil
        print("🔄 DEBUG: Results reset - ready for new recording")
    }
    
    func parseURLParameters(from urlString: String) {
        print("🔍 DEBUG: Parsing URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ DEBUG: Failed to create URL from string")
            DispatchQueue.main.async {
                self.passageId = nil
                self.chunkId = nil
                self.hasPassageId = false
                self.updateDebugInfo(url: urlString, passageId: nil, chunkId: nil, hasPassage: false)
            }
            return
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ DEBUG: Failed to create URLComponents")
            DispatchQueue.main.async {
                self.passageId = nil
                self.chunkId = nil
                self.hasPassageId = false
                self.updateDebugInfo(url: urlString, passageId: nil, chunkId: nil, hasPassage: false)
            }
            return
        }
        
        let queryItems = components.queryItems
        print("🔍 DEBUG: Query items: \(queryItems?.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: ", ") ?? "none")")
        
        let newPassageId = queryItems?.first { $0.name == "passageId" }?.value
        let newChunkId = queryItems?.first { $0.name == "chunk" }?.value
        let newHasPassageId = newPassageId != nil && !newPassageId!.isEmpty || alwaysShowRecordingButton
        
        print("✅ DEBUG: passageId=\(newPassageId ?? "nil"), chunkId=\(newChunkId ?? "nil"), hasPassageId=\(newHasPassageId)")
        
        DispatchQueue.main.async {
            print("🔄 DEBUG: About to update @Published properties on main thread")
            self.passageId = newPassageId
            self.chunkId = newChunkId
            self.hasPassageId = newHasPassageId
            self.updateDebugInfo(url: urlString, passageId: newPassageId, chunkId: newChunkId, hasPassage: newHasPassageId)
            print("🔄 DEBUG: All @Published properties updated - hasPassageId=\(self.hasPassageId)")
            
            // Force objectWillChange notification
            self.objectWillChange.send()
            print("📡 DEBUG: Sent objectWillChange notification")
        }
    }
    
    private func updateDebugInfo(url: String, passageId: String?, chunkId: String?, hasPassage: Bool) {
        var info = "URL: \(url)\n"
        info += "PassageId: \(passageId ?? "none")\n"
        info += "ChunkId: \(chunkId ?? "none")\n"
        info += "HasPassageId: \(hasPassage)\n"
        info += "AlwaysShow: \(alwaysShowRecordingButton)"
        debugInfo = info
    }
    
    private func buildNotesString() -> String {
        var components: [String] = []
        
        if let passageId = passageId {
            components.append("Passage: \(passageId)")
        }
        
        if let chunkId = chunkId {
            components.append("Chunk: \(chunkId)")
        }
        
        if !components.isEmpty {
            return components.joined(separator: ", ")
        } else {
            return "Web Reading - \(currentURL)"
        }
    }
}

// MARK: - Navigation Delegate
class WebNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var viewModel: WebReadingPassageViewModel?
    
    init(viewModel: WebReadingPassageViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            print("🌐 DEBUG: WebView didCommit navigation to: \(url)")
            DispatchQueue.main.async {
                self.viewModel?.currentURL = url
                self.viewModel?.parseURLParameters(from: url)
            }
        } else {
            print("⚠️ DEBUG: WebView didCommit but no URL available")
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            print("✅ DEBUG: WebView didFinish loading: \(url)")
            DispatchQueue.main.async {
                self.viewModel?.currentURL = url
                self.viewModel?.parseURLParameters(from: url)
                self.viewModel?.isWebViewLoading = false
            }
            viewModel?.startURLMonitoring(webView: webView)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.viewModel?.isWebViewLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url?.absoluteString {
            print("🔍 DEBUG: WebView deciding policy for: \(url)")
        }
        decisionHandler(.allow)
    }
}