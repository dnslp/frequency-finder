import SwiftUI
import Combine
import MicrophonePitchDetector

class ReadingPassageViewModel: ObservableObject {
    @Published var selectedPassageIndex = 0
    @Published var fontSize: CGFloat = 16
    @Published var selectedFont: String = "System"

    @Published var isRecording = false
    @Published var showResult = false
    @Published var promptRerecord = false
    @Published var calculatedF0: Double?
    @Published var pitchStdDev: Double?
    @Published var pitchMin: Double?
    @Published var pitchMax: Double?
    @Published var elapsedTime: TimeInterval = 0
    @Published var smoothedPitch: Double = 0
    @Published var wavePhase = 0.0

    private var pitchDetector = MicrophonePitchDetector()
    private var pitchSamples: [Double] = []
    private var startTime: Date?
    private var duration: TimeInterval = 0

    private var waveTimer: Timer?
    private var pitchTimer: Timer?
    private var elapsedTimer: Timer?

    let availableFonts = ["System", "Times New Roman", "Georgia", "Helvetica", "Verdana", "Courier New"]
    let minSessionDuration: TimeInterval = 6.0
    let minSampleCount: Int = 12
    private let pitchSmoothingFactor: Double = 0.1

    @ObservedObject var profileManager: UserProfileManager

    init(profileManager: UserProfileManager) {
        self.profileManager = profileManager
    }

    func activatePitchDetector() {
        Task {
            do {
                try await pitchDetector.activate()
            } catch {
                print("❌ Microphone error: \(error)")
            }
        }
    }

    func invalidateTimers() {
        waveTimer?.invalidate()
        pitchTimer?.invalidate()
        elapsedTimer?.invalidate()
        waveTimer = nil
        pitchTimer = nil
        elapsedTimer = nil
    }

    func startRecording() {
        pitchSamples.removeAll()
        startTime = Date()
        elapsedTime = 0
        isRecording = true
        promptRerecord = false
        showResult = false

        wavePhase = 0
        waveTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.wavePhase += 0.15
        }

        pitchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let pitch = self.pitchDetector.pitch
            if pitch > 55 && pitch < 500 {
                self.pitchSamples.append(pitch)
                self.smoothedPitch = self.smoothedPitch * (1 - self.pitchSmoothingFactor) + pitch * self.pitchSmoothingFactor
            }
        }

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if let start = self?.startTime {
                self?.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stopRecording() {
        isRecording = false
        invalidateTimers()
        duration = Date().timeIntervalSince(startTime ?? Date())

        guard duration >= minSessionDuration, pitchSamples.count >= minSampleCount else {
            promptRerecord = true
            print("❗️ Not enough valid data: duration = \(duration), samples = \(pitchSamples.count)")
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

            profileManager.addSession(
                type: .readingAnalysis,
                pitchSamples: pitchSamples,
                duration: duration,
                notes: ReadingPassage.passages[selectedPassageIndex].title
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
}
