import SwiftUI
import Combine
import MicrophonePitchDetector

class ReadingPassageViewModel: ObservableObject {
    // Dependencies
    private let pitchDetector = MicrophonePitchDetector()
    private let profileManager: UserProfileManager

    // Published properties for the View
    @Published var selectedPassageIndex = 0
    @Published var isRecording = false
    @Published var showResult = false
    @Published var promptRerecord = false
    @Published var calculatedF0: Double?
    @Published var elapsedTime: TimeInterval = 0
    @Published var smoothedPitch: Double = 0.0
    @Published var wavePhase: Double = 0.0

    // Private state
    private var pitchSamples: [Double] = []
    private var startTime: Date?
    private var duration: TimeInterval = 0

    private var pitchTimer: Timer?
    private var waveTimer: Timer?
    private var elapsedTimer: Timer?

    // Constants
    private let minSessionDuration: TimeInterval = 6.0
    private let minSampleCount: Int = 12
    private let pitchSmoothingFactor: Double = 0.1

    init(profileManager: UserProfileManager) {
        self.profileManager = profileManager

        Task {
            do {
                try await pitchDetector.activate()
            } catch {
                // TODO: Propagate this error to the UI
                print("❌ Microphone error: \(error)")
            }
        }
    }

    deinit {
        cleanupTimers()
    }

    // MARK: - Public API

    func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    func startRecording() {
        pitchSamples.removeAll()
        startTime = Date()
        elapsedTime = 0
        promptRerecord = false
        showResult = false
        isRecording = true

        startTimers()
        HapticManager.shared.impact(.light)
    }

    func stopRecording() {
        isRecording = false
        cleanupTimers()
        duration = Date().timeIntervalSince(startTime ?? Date())

        HapticManager.shared.impact(.light)

        guard duration >= minSessionDuration, pitchSamples.count >= minSampleCount else {
            promptRerecord = true
            print("❗️ Not enough valid data: duration = \(duration), samples = \(pitchSamples.count)")
            return
        }

        let statsCalculator = StatisticsCalculator()
        let filteredSamples = statsCalculator.removeOutliers(from: pitchSamples)
        let median = filteredSamples.median()

        calculatedF0 = median
        showResult = true
        HapticManager.shared.impact(.medium)

        profileManager.addSession(
            type: .readingAnalysis,
            pitchSamples: filteredSamples,
            duration: duration,
            notes: passages[selectedPassageIndex].title
        )
    }

    // MARK: - Private Helpers

    private func startTimers() {
        // Wave visualizer phase
        wavePhase = 0
        waveTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.wavePhase += 0.15
        }

        // Pitch sampling
        pitchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let pitch = self.pitchDetector.pitch
            if pitch > 40 && pitch < 1000 {
                self.pitchSamples.append(pitch)
                self.smoothedPitch = self.smoothedPitch * (1 - self.pitchSmoothingFactor) + pitch * self.pitchSmoothingFactor
            }
        }

        // Elapsed time display
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if let start = self?.startTime {
                self?.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func cleanupTimers() {
        waveTimer?.invalidate()
        pitchTimer?.invalidate()
        elapsedTimer?.invalidate()
        waveTimer = nil
        pitchTimer = nil
        elapsedTimer = nil
    }
}
