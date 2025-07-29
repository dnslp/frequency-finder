//
//  ReadingPassageSessionView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//


import SwiftUI
import Combine
import MicrophonePitchDetector

struct ReadingPassageSessionView: View {
    @ObservedObject var profileManager: UserProfileManager
    @StateObject private var pitchDetector = MicrophonePitchDetector()
    
    @State private var wavePhase = 0.0
    @State private var waveTimer: Timer?

    @State private var isRecording = false
    @State private var pitchSamples: [Double] = []
    @State private var startTime: Date?
    @State private var pitchTimer: Timer?

    @State private var showResult = false
    @State private var promptRerecord = false
    @State private var calculatedF0: Double?
    @State private var duration: TimeInterval = 0

    @State private var selectedPassageIndex = 0
    @State private var fontSize: CGFloat = 16
    @State private var selectedFont: String = "System"

    let availableFonts = ["System", "Times New Roman", "Georgia", "Helvetica", "Verdana"]

    // Validation thresholds
    let minSessionDuration: TimeInterval = 6.0   // seconds
    let minSampleCount: Int = 12                 // samples (if using 0.5s intervals)

    @State private var smoothedPitch: Double = 0
    @State private var pitchSmoothingFactor: Double = 0.1  // 0.0 = no smoothing, 1.0 = instant jump
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var elapsedTimer: Timer?
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    
    var body: some View {
        VStack(spacing: 24) {
            Text("📖 Reading Analysis")
                .font(.title2)
                .bold()

            TabView(selection: $selectedPassageIndex) {
                ForEach(passages.indices, id: \.self) { index in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(passages[index].title)
                                .font(Font.custom(selectedFont, size: fontSize + 2).weight(.bold))
                            Text(passages[index].text)
                                .font(Font.custom(selectedFont, size: fontSize))
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 300)

            HStack {
                Button(action: {
                    if selectedPassageIndex > 0 {
                        selectedPassageIndex -= 1
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                .disabled(selectedPassageIndex == 0)

                Spacer()

                Button(action: {
                    if selectedPassageIndex < passages.count - 1 {
                        selectedPassageIndex += 1
                    }
                }) {
                    Image(systemName: "arrow.right")
                }
                .disabled(selectedPassageIndex == passages.count - 1)
            }
            .padding(.horizontal)

            HStack {
                Picker("Font", selection: $selectedFont) {
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.menu)

                Stepper("Size: \(Int(fontSize))", value: $fontSize, in: 12...28)
            }
            .padding(.horizontal)


            Button(isRecording ? "Stop Recording" : "Start Recording") {
                isRecording ? stopRecording() : startRecording()
            }
            .padding()
            .buttonStyle(.borderedProminent)

            if isRecording {
                Text("🎙️ Recording...").foregroundColor(.green)
                Text("⏱ Elapsed: \(formatTime(elapsedTime))")
                SineWaveView(
                    frequency: max(0.5, min(smoothedPitch / 200, 6.0)), // normalized
                    amplitude: 0.6,
                    phase: wavePhase
                )
                .transition(.opacity)
                .animation(.easeInOut, value: pitchDetector.pitch)
            }

            if showResult, let f0 = calculatedF0 {
                VStack(spacing: 8) {
                    Text("Session Complete")
                        .font(.headline)
                    Text("Estimated f₀: \(f0, specifier: "%.1f") Hz")
                        .foregroundColor(.secondary)
                }
            }

            if promptRerecord {
                Text("Recording too short or invalid. Please try again.")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onDisappear {
            pitchTimer?.invalidate()
        }
        .task {
            do {
                try await pitchDetector.activate()
            } catch {
                print("❌ Microphone error: \(error)")
            }
        }
    }

    func startRecording() {
        pitchSamples.removeAll()
        startTime = Date()
        elapsedTime = 0
        isRecording = true
        promptRerecord = false
        showResult = false

        // Update visualizer phase
        wavePhase = 0
        waveTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            wavePhase += 0.15
        }

        // Update pitch and smooth pitch
        pitchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let pitch = pitchDetector.pitch
            if pitch > 40 && pitch < 1000 {
                pitchSamples.append(pitch)
                smoothedPitch = smoothedPitch * (1 - pitchSmoothingFactor) + pitch * pitchSmoothingFactor
            }
        }

        // Timer for elapsed time
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stopRecording() {
        isRecording = false
        pitchTimer?.invalidate()
        pitchTimer = nil
        duration = Date().timeIntervalSince(startTime ?? Date())
        
        waveTimer?.invalidate()
        pitchTimer?.invalidate()
        elapsedTimer?.invalidate()
        waveTimer = nil
        pitchTimer = nil
        elapsedTimer = nil

        // Validation checks
        guard duration >= minSessionDuration, pitchSamples.count >= minSampleCount else {
            promptRerecord = true
            print("❗️ Not enough valid data: duration = \(duration), samples = \(pitchSamples.count)")
            return
        }

        let filtered = trimOutliers(from: pitchSamples)
        let median = filtered.median()

        calculatedF0 = median
        showResult = true

        profileManager.addSession(
            type: .readingAnalysis,
            pitchSamples: filtered,
            duration: duration,
            notes: passages[selectedPassageIndex].title
        )
    }

    func trimOutliers(from samples: [Double]) -> [Double] {
        guard samples.count >= 5 else { return samples }
        let mean = samples.mean()
        let std = samples.standardDeviation()
        let threshold = std * 1.5
        return samples.filter { abs($0 - mean) <= threshold }
    }
}
