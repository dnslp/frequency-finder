import SwiftUI
import Combine

struct TunerView: View {
    @ObservedObject var viewModel: TunerViewModel
    
    @AppStorage("HidesTranspositionMenu")
    private var hidesTranspositionMenu = false
    
    var body: some View {
#if os(watchOS)
        watchView
#else
        iOSView
#endif
    }
    
    // MARK: - iOS View
    @ViewBuilder
    private var iOSView: some View {
        VStack(alignment: .noteCenter) {
            if !hidesTranspositionMenu {
                HStack {
                    TranspositionMenu(selectedTransposition: $viewModel.selectedTransposition)
                        .padding()
                    Spacer()
                }
            }
            
            Spacer()
            
            Group {
                Text("Target: \(viewModel.targetFrequencyString)")
                Text("Actual: \(viewModel.actualFrequencyString)")
                Text("Note: \(viewModel.noteNameString) \(viewModel.octave)")
                Text("Harmonics: \(viewModel.harmonicsString)")
            }
            
            Spacer()
        }
    }
    
    
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            viewModel: TunerViewModel()
        )
    }
}
