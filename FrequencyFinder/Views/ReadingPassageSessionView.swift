//
//  ReadingPassageSessionView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import SwiftUI
import Combine

struct ReadingPassageSessionView: View {
    @StateObject private var viewModel: ReadingPassageViewModel
    
    // UI-specific state that doesn't belong in the ViewModel
    @State private var fontSize: CGFloat = 16
    @State private var selectedFont: String = "System"
    
    let availableFonts = ["System", "Times New Roman", "Georgia", "Helvetica", "Verdana"]
    
    // Initializer to inject the UserProfileManager
    init(profileManager: UserProfileManager) {
        _viewModel = StateObject(wrappedValue: ReadingPassageViewModel(profileManager: profileManager))
    }

    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all) // Darker container

                ScrollView {
                    VStack(spacing: 24) {
                        Text("📖 Reading Analysis")
                            .font(.title2)
                            .bold()

                        TabView(selection: $viewModel.selectedPassageIndex) {
                            ForEach(passages.indices, id: \.self) { index in
                                CardView {
                                    PassageTextView(passage: passages[index])
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 350)

                        passageNavigation

                        if geometry.size.width < 350 && sizeClass == .compact {
                            VStack {
                                fontControls
                            }
                        } else {
                            HStack {
                                fontControls
                            }
                        }

                        RecordingControlsView(
                            isRecording: $viewModel.isRecording,
                            elapsedTime: $viewModel.elapsedTime
                        ) {
                            viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                        }

                        if viewModel.isRecording {
                            SineWaveView(
                                frequency: max(0.5, min(viewModel.smoothedPitch / 200, 6.0)),
                                amplitude: 0.6,
                                phase: viewModel.wavePhase
                            )
                            .transition(.opacity)
                            .animation(.easeInOut, value: viewModel.smoothedPitch)
                            .frame(height: 50)
                        }

                        if viewModel.showResult, let f0 = viewModel.calculatedF0 {
                            VStack(spacing: 8) {
                                Text("Session Complete")
                                    .font(.headline)
                                Text("Estimated f₀: \(f0, specifier: "%.1f") Hz")
                                    .foregroundColor(.secondary)
                            }
                        }

                        if viewModel.promptRerecord {
                            Text("Recording too short or invalid. Please try again.")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    @ViewBuilder
    private var passageNavigation: some View {
        HStack {
            Button(action: {
                if viewModel.selectedPassageIndex > 0 {
                    viewModel.selectedPassageIndex -= 1
                }
            }) {
                Image(systemName: "arrow.left")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(viewModel.selectedPassageIndex == 0)

            Spacer()

            Button(action: {
                if viewModel.selectedPassageIndex < passages.count - 1 {
                    viewModel.selectedPassageIndex += 1
                }
            }) {
                Image(systemName: "arrow.right")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(viewModel.selectedPassageIndex == passages.count - 1)
        }
    }

    @ViewBuilder
    private var fontControls: some View {
        Picker("Font", selection: $selectedFont) {
            ForEach(availableFonts, id: \.self) { font in
                Text(font).tag(font)
            }
        }
        .pickerStyle(.menu)
        
        Stepper("Size: \(Int(fontSize))", value: $fontSize, in: 12...28)
    }
}

struct ReadingPassageSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingPassageSessionView(profileManager: UserProfileManager())
    }
}
