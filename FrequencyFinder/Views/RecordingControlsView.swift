import SwiftUI

struct RecordingControlsView: View {
    @Binding var isRecording: Bool
    @Binding var elapsedTime: TimeInterval

    var onToggleRecording: () -> Void

    @State private var isPressed: Bool = false

    private let maxDuration: TimeInterval = 30.0 // Assuming a max duration for the progress bar

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Custom Progress Bar
            VStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(height: 10)
                            .foregroundColor(Color.gray.opacity(0.3))

                        Capsule()
                            .frame(width: geometry.size.width * CGFloat(elapsedTime / maxDuration), height: 10)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentColor, Color("accentSecondary")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .animation(.easeInOut, value: elapsedTime)
                    }
                }
                .frame(height: 10)

                Text(formatTime(elapsedTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .opacity(isRecording ? 1.0 : 0.0)
            .animation(.easeInOut, value: isRecording)

            // MARK: - Recording Button
            Button(action: {
                onToggleRecording()
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(isRecording ? Color.red : Color.accentColor)
            .clipShape(Capsule())
            .scaleEffect(isPressed ? 1.05 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in isPressed = true })
                    .onEnded({ _ in isPressed = false })
            )
            .animation(.easeInOut(duration: 0.2), value: isRecording) // Color change animation
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
