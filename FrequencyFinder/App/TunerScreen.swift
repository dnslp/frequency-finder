import SwiftUI

struct TunerScreen: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var tunerData = TunerData()
    @AppStorage("modifierPreference")
    private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition")
    private var selectedTransposition = 0

    var body: some View {
        VStack {
            HStack {
                Button(audioManager.isListening ? "Stop Tuning" : "Start Tuning") {
                    if audioManager.isListening {
                        audioManager.stop()
                    } else {
                        audioManager.start()
                    }
                }
                .padding()
                Spacer()
            }
            
            TunerView(
                tunerData: tunerData,
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
        }
        .opacity(audioManager.isListening ? 1 : 0.5)
        .animation(.easeInOut, value: audioManager.isListening)
        .onChange(of: audioManager.frequency) { frequency in
            tunerData.updatePitch(to: Double(frequency))
        }
        .onChange(of: audioManager.amplitude) { amplitude in
            tunerData.amplitude = Double(amplitude)
        }
    }
}

struct TunerScreen_Previews: PreviewProvider {
    static var previews: some View {
        TunerScreen()
    }
}
