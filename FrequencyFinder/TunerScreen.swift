import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @StateObject private var pitchDetector = MicrophonePitchDetector()
    @StateObject private var viewModel = TunerViewModel(pitchTracker: PitchTracker())

    @AppStorage("modifierPreference")
    private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition")
    private var selectedTransposition = 0

    var body: some View {
        TunerView(viewModel: viewModel)
            .onAppear {
                viewModel.modifierPreference = modifierPreference
                viewModel.selectedTransposition = selectedTransposition
            }
            .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5)
            .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
            .task {
                do {
                    try await pitchDetector.activate()
                } catch {
                    // TODO: Handle error
                    print(error)
                }
            }
            .alert(isPresented: $pitchDetector.showMicrophoneAccessAlert) {
                MicrophoneAccessAlert()
            }
            .onChange(of: pitchDetector.pitch) { _, newPitch in
                viewModel.updatePitch(to: newPitch)
            }
            .onChange(of: modifierPreference) { _, newValue in
                viewModel.modifierPreference = newValue
            }
            .onChange(of: selectedTransposition) { _, newValue in
                viewModel.selectedTransposition = newValue
            }
            .onReceive(viewModel.$selectedTransposition) { newValue in
                if selectedTransposition != newValue {
                    selectedTransposition = newValue
                }
            }
            .onReceive(viewModel.$modifierPreference) { newValue in
                if modifierPreference != newValue {
                    modifierPreference = newValue
                }
            }
    }
}

struct TunerScreen_Previews: PreviewProvider {
    static var previews: some View {
        TunerScreen()
    }
}
