import SwiftUI
import UIKit

struct ReadingPassageSessionView: View {
    @StateObject private var viewModel: ReadingPassageViewModel
    @State private var isRecordButtonPressed = false


    init(profileManager: UserProfileManager) {
        _viewModel = StateObject(wrappedValue: ReadingPassageViewModel(profileManager: profileManager))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        CardView { PassageSelectionView(viewModel: viewModel) }
                        CardView { PassageTextView(viewModel: viewModel) }

                        if viewModel.isRecording {
                            CardView { RecordingStatusView(viewModel: viewModel) }
                        } else if viewModel.showResult {
                            CardView { ResultsView(viewModel: viewModel) }
                                .onAppear { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                        }

                        if viewModel.promptRerecord {
                            Text("Recording too short or invalid. Please try again.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.red)
                                .padding(.top)
                        }
                        
                        // Recording Controls
                        CardView {
                            RecordingControlsView(viewModel: viewModel, isPressed: $isRecordButtonPressed)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Reading Analysis")
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

                // Soft blue glow border when recording
                if viewModel.isRecording {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.blue.opacity(0.8), lineWidth: 10)
                        .blur(radius: 5)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Card Container
struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Passage Picker
struct PassageSelectionView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    var body: some View {
        Picker("Passage", selection: $viewModel.selectedPassageIndex) {
            ForEach(ReadingPassage.passages.indices, id: \.self) { idx in
                Text(ReadingPassage.passages[idx].title).tag(idx)
            }
        }
        .pickerStyle(.menu)
        .disabled(viewModel.isRecording)
    }
}

// MARK: - Passage Display with Fade Effect
struct PassageTextView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    var body: some View {
        let p = ReadingPassage.passages[viewModel.selectedPassageIndex]
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(p.title)
                            .font(Font.custom(viewModel.selectedFont, size: viewModel.fontSize + 4).weight(.semibold))
                        Spacer()
                        Text(p.skillFocus)
                            .font(.caption2.bold())
                            .padding(6)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                    Text(p.text)
                        .font(Font.custom(viewModel.selectedFont, size: viewModel.fontSize))
                        .lineSpacing(viewModel.fontSize * 0.2)
                        .multilineTextAlignment(.leading)
                }
                .padding()
            }
            .frame(height: 300)
            .clipped()

            // Fade overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0),
                            .init(color: Color(.secondarySystemBackground), location: 1)
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: 60)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Recording Controls
struct RecordingControlsView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    @Binding var isPressed: Bool
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Picker("Font", selection: $viewModel.selectedFont) {
                    ForEach(viewModel.availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.menu)
                .disabled(viewModel.isRecording)

                Stepper(value: $viewModel.fontSize, in: 12...28) {
                    Text("Size: \(Int(viewModel.fontSize))")
                }
                .disabled(viewModel.isRecording)
            }
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
    }
}

// MARK: - Recording Status
struct RecordingStatusView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
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
    }
}

// MARK: - Gradient Progress Bar
struct GradientProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray5))
                Capsule()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.6)]),
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut, value: progress)
            }
        }
    }
}

// MARK: - Results View
struct ResultsView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    var body: some View {
        VStack(spacing: 16) {
            Text("Session Complete 🎉").font(.title3.weight(.semibold))
            Text("Passage: \(ReadingPassage.passages[viewModel.selectedPassageIndex].title)")
                .font(.subheadline)
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
    }
}

// MARK: - Preview
struct ReadingPassageSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingPassageSessionView(profileManager: UserProfileManager())
    }
}
