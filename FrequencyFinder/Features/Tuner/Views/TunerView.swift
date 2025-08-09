import SwiftUI
import Combine

struct TunerView: View {
    @ObservedObject var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    @State private var localCentsOffset: Double = 0
    
    @AppStorage("HidesTranspositionMenu")
    private var hidesTranspositionMenu = false
    
    private let updateTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }
    
    var body: some View {
#if os(watchOS)
        watchView
#else
        iOSView
            .onReceive(updateTimer) { _ in
                localCentsOffset = tunerData.deltaCents
            }
#endif
    }
    
    // MARK: - iOS View
    @ViewBuilder
    private var iOSView: some View {
        VStack(alignment: .noteCenter) {
            if !hidesTranspositionMenu {
                HStack {
                    TranspositionMenu(selectedTransposition: $selectedTransposition)
                        .padding()
                    Spacer()
                }
            }
            
            Spacer()
            
            Group {
                Text("Target: \(tunerData.closestNote.frequency.measurement.value, specifier: "%.1f") Hz")
                Text("Actual: \(tunerData.pitch.measurement.value, specifier: "%.1f") Hz")
                Text("Note: \(tunerData.closestNote.note.names) \(tunerData.closestNote.octave)")
                Text("Harmonics: \(tunerData.harmonics)")
            }
            
            Spacer()
        }
    }
    
    
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: TunerData(),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
    }
}
