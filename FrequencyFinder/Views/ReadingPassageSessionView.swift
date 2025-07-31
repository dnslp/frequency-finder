import SwiftUI

struct ReadingPassageSessionView: View {
    @StateObject private var viewModel: ReadingPassageViewModel

    init(profileManager: UserProfileManager) {
        _viewModel = StateObject(wrappedValue: ReadingPassageViewModel(profileManager: profileManager))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Content of the VStack
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

            PassageTextView(viewModel: viewModel)

            RecordingControlsView(viewModel: viewModel)

            if viewModel.isRecording {
                RecordingStatusView(viewModel: viewModel)
            }

            if viewModel.showResult {
                ResultsView(viewModel: viewModel)
            }

            if viewModel.promptRerecord {
                Text("Recording too short or invalid. Please try again.")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onDisappear {
            viewModel.invalidateTimers()
        }
        .task {
            viewModel.activatePitchDetector()
        }
    }
}

struct PassageSelectionView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel

    var body: some View {
        HStack {
            Picker("Passage", selection: $viewModel.selectedPassageIndex) {
                ForEach(ReadingPassage.passages.indices, id: \.self) { index in
                    let passage = ReadingPassage.passages[index]
                    Text("\(passage.title) (\(passage.skillFocus))").tag(index)
                }
            }
            .pickerStyle(.menu)
            .disabled(viewModel.isRecording)
        }
    }
}

struct PassageTextView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let passage = ReadingPassage.passages[viewModel.selectedPassageIndex]
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
        .frame(height: 300)
    }
}

struct RecordingControlsView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel

    var body: some View {
        VStack {
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
                viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
            }
            .padding()
            .buttonStyle(.borderedProminent)
        }
    }
}

struct RecordingStatusView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel

    var body: some View {
        VStack {
            Text("🎙️ Recording...").foregroundColor(.green)
            Text("⏱ Elapsed: \(viewModel.formatTime(viewModel.elapsedTime))")

            ProgressView(value: viewModel.elapsedTime, total: viewModel.minSessionDuration) {
                Text("Min. recording time")
            }
            .progressViewStyle(.linear)
            .padding(.horizontal)

            SineWaveView(
                frequency: max(0.5, min(viewModel.smoothedPitch / 200, 6.0)), // normalized
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
            Text("Session Complete 🎉")
                .font(.headline)

            Text("Passage: \(ReadingPassage.passages[viewModel.selectedPassageIndex].title)")
                .font(.subheadline)

            if let f0 = viewModel.calculatedF0,
               let stdDev = viewModel.pitchStdDev,
               let minPitch = viewModel.pitchMin,
               let maxPitch = viewModel.pitchMax {

                VStack(spacing: 8) {
                    Text("Average Pitch (f₀): \(f0, specifier: "%.1f") Hz")
                        .font(.body)

                    Divider()

                    Text("Pitch Stability: \(stdDev, specifier: "%.1f") Hz")
                        .font(.body)
                    Text("A lower number means a more steady pitch.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Pitch Range: \(minPitch, specifier: "%.1f") - \(maxPitch, specifier: "%.1f") Hz")
                        .font(.body)
                    Text("This shows the lowest and highest notes you used.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}
