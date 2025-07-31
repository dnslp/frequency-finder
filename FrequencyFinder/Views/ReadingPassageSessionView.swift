import SwiftUI

struct ReadingPassageSessionView: View {
    @StateObject private var viewModel: ReadingPassageViewModel

    init(profileManager: UserProfileManager) {
        _viewModel = StateObject(wrappedValue: ReadingPassageViewModel(profileManager: profileManager))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("📖 Reading Analysis")
                .font(.title2)
                .bold()

            PassageSelectionView(viewModel: viewModel)

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
                    Text(ReadingPassage.passages[index].title).tag(index)
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
                Text(passage.title)
                    .font(Font.custom(viewModel.selectedFont, size: viewModel.fontSize + 2).weight(.bold))
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
        VStack(spacing: 8) {
            Text("Session Complete")
                .font(.headline)
            if let f0 = viewModel.calculatedF0 {
                Text("Passage: \(ReadingPassage.passages[viewModel.selectedPassageIndex].title)")
                Text("Estimated f₀: \(f0, specifier: "%.1f") Hz")
                    .foregroundColor(.secondary)
            }
        }
    }
}
