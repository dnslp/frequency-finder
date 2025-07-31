import SwiftUI

struct ReadingPassageSessionView: View {
    // Inject UserProfileManager to VM via initializer
    @StateObject private var viewModel: ReadingPassageViewModel

    init(profileManager: UserProfileManager) {
        _viewModel = StateObject(
            wrappedValue: ReadingPassageViewModel(profileManager: profileManager)
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Passage selector
                    PassageSelectionView(viewModel: viewModel)

                    // Passage text display
                    PassageTextView(viewModel: viewModel)

                    // Recording controls (font, size, start/stop)
                    RecordingControlsView(viewModel: viewModel)

                    // Recording status or results
                    if viewModel.isRecording {
                        RecordingStatusView(viewModel: viewModel)
                    } else if viewModel.showResult {
                        ResultsView(viewModel: viewModel)
                    }

                    // Re-record prompt
                    if viewModel.promptRerecord {
                        Text("Recording too short or invalid. Please try again.")
                            .foregroundColor(.red)
                            .padding(.top)
                    }
                }
                .padding()
            }
            .navigationTitle("Reading Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("🔥 \(viewModel.profileManager.currentProfile.analytics.streakDays) Day Streak")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SessionHistoryView(profileManager: viewModel.profileManager)) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .onDisappear {
                viewModel.invalidateTimers()
            }
            .task {
                await viewModel.activatePitchDetector()
            }
        }
    }
}

// MARK: - Subviews

struct PassageSelectionView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    var body: some View {
        Picker("Passage", selection: $viewModel.selectedPassageIndex) {
            ForEach(ReadingPassage.passages.indices, id: \.self) { idx in
                let p = ReadingPassage.passages[idx]
                Text("\(p.title) (\(p.skillFocus))").tag(idx)
            }
        }
        .pickerStyle(.menu)
        .disabled(viewModel.isRecording)
    }
}

struct PassageTextView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel

    var body: some View {
        let passage = ReadingPassage.passages[viewModel.selectedPassageIndex]
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(passage.title)
                        .font(Font.custom(viewModel.selectedFont, size: viewModel.fontSize + 2).weight(.bold))
                    Spacer()
                    Text(passage.skillFocus)
                        .font(.caption)
                        .padding(4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
                Text(passage.text)
                    .font(Font.custom(viewModel.selectedFont, size: viewModel.fontSize))
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
        .frame(height: 400)
    }
}

struct RecordingControlsView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Font", selection: $viewModel.selectedFont) {
                    ForEach(viewModel.availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.menu)
                .disabled(viewModel.isRecording)

                Stepper("Size: \(Int(viewModel.fontSize))", value: $viewModel.fontSize, in: 12...28)
                    .disabled(viewModel.isRecording)
            }
            .padding(.horizontal)

            Button(viewModel.isRecording ? "Stop Recording" : "Start Recording") {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct RecordingStatusView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    var body: some View {
        VStack(spacing: 12) {
            Text("🎙️ Recording...")
                .foregroundColor(.green)
            Text("⏱ Elapsed: \(viewModel.formatTime(viewModel.elapsedTime))")

            ProgressView(value: viewModel.elapsedTime, total: viewModel.minSessionDuration) {
                Text("Min. recording time")
            }
            .progressViewStyle(.linear)
            .padding(.horizontal)

            SineWaveView(
                frequency: max(0.5, min(viewModel.smoothedPitch / 200, 6.0)),
                amplitude: 0.6,
                phase: viewModel.wavePhase
            )
            .transition(.opacity)
            .animation(.easeInOut, value: viewModel.smoothedPitch)
        }
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    var body: some View {
        VStack(spacing: 12) {
            Text("Session Complete 🎉").font(.headline)
            Text("Passage: \(ReadingPassage.passages[viewModel.selectedPassageIndex].title)")
                .font(.subheadline)

            if let f0 = viewModel.calculatedF0,
               let stdDev = viewModel.pitchStdDev,
               let minPitch = viewModel.pitchMin,
               let maxPitch = viewModel.pitchMax {
                VStack(spacing: 8) {
                    Text("Average Pitch (f₀): \(f0, specifier: "%.1f") Hz")
                    Divider()
                    Text("Pitch Stability: \(stdDev, specifier: "%.1f") Hz")
                        .font(.caption).foregroundColor(.secondary)
                    Divider()
                    Text("Pitch Range: \(minPitch, specifier: "%.1f") - \(maxPitch, specifier: "%.1f") Hz")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding().background(Color(.systemGray6)).cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Preview
struct ReadingPassageSessionView_Previews: PreviewProvider {
    static var previews: some View {
        let profileManager = UserProfileManager()
        ReadingPassageSessionView(profileManager: profileManager)
    }
}
