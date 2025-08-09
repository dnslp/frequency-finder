import SwiftUI
import AVFoundation

struct TunerScreen: View {
    @ObservedObject private var sharedAudioManager = SharedAudioManager.shared
    @StateObject private var tunerData = TunerData()
    @AppStorage("modifierPreference")
    private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition")
    private var selectedTransposition = 0
    @State private var showMicrophoneAlert = false
    
    private var audioManager: AudioManager {
        sharedAudioManager.audioManager
    }

    var body: some View {
        VStack {
            // Start/Stop Controls
            HStack {
                Button(action: {
                    if sharedAudioManager.isActive {
                        sharedAudioManager.stopSession()
                    } else {
                        startTuningSession()
                    }
                }) {
                    HStack {
                        Image(systemName: audioManager.isListening ? "stop.circle.fill" : "play.circle.fill")
                        Text(audioManager.isListening ? "Stop Tuning" : "Start Tuning")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(audioManager.isListening ? Color.red : Color.green)
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Session info
                if audioManager.isListening {
                    VStack(alignment: .trailing) {
                        Text("Session Active")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Pitches: \(audioManager.tuningSession.pitchHistory.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            TunerView(
                tunerData: tunerData,
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
            
            // Real-time audio data section (only when active)
            if audioManager.isListening {
                VStack(spacing: 8) {
                    Text("🎤 Live Audio Analysis")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    HStack(spacing: 20) {
                        // Frequency Display
                        VStack {
                            Text("Frequency")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(audioManager.frequency, specifier: "%.1f") Hz")
                                .font(.title2)
                                .monospaced()
                                .foregroundColor(audioManager.frequency > 0 ? .primary : .gray)
                            // Update indicator
                            Circle()
                                .fill(audioManager.frequency > 0 ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.1), value: audioManager.frequency)
                        }
                        
                        // Note Display  
                        VStack {
                            Text("Note")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(audioManager.note.isEmpty ? "--" : audioManager.note)
                                .font(.title2)
                                .monospaced()
                                .foregroundColor(audioManager.note.isEmpty ? .gray : .blue)
                        }
                        
                        // Cents Display
                        VStack {
                            Text("Cents")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(audioManager.note.isEmpty ? "--" : "\(audioManager.cents, specifier: "%.0f")")
                                .font(.title2)
                                .monospaced()
                                .foregroundColor(abs(audioManager.cents) < 10 ? .green : .orange)
                        }
                    }
                    
                    // Debug info
                    Text(audioManager.debugInfo)
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(audioManager.frequency > 0 ? Color.green : Color.gray, lineWidth: 2)
                        )
                )
                .padding()
            }
        }
        .opacity(audioManager.isListening && audioManager.frequency > 0 ? 1 : 0.5)
        .animation(.easeInOut, value: audioManager.isListening)
        .onChange(of: audioManager.frequency) { newFrequency in
            print("📊 TunerScreen: Frequency changed to \(newFrequency)")
            tunerData.updatePitch(to: Double(newFrequency))
        }
        .onChange(of: audioManager.note) { newNote in
            print("📊 TunerScreen: Note changed to \(newNote)")
        }
        .onDisappear {
            // Always stop when leaving the tab to prevent conflicts
            print("🎤 TunerScreen: onDisappear - stopping AudioManager")
            sharedAudioManager.stopSession()
        }
        .alert("Microphone Access Required", isPresented: $showMicrophoneAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("FrequencyFinder needs microphone access to detect pitch. Please enable it in Settings.")
        }
    }
    
    private func startTuningSession() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            sharedAudioManager.startSession(context: .tuner)
        case .denied:
            showMicrophoneAlert = true
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        sharedAudioManager.startSession(context: .tuner)
                    } else {
                        showMicrophoneAlert = true
                    }
                }
            }
        @unknown default:
            showMicrophoneAlert = true
        }
    }
}

struct TunerScreen_Previews: PreviewProvider {
    static var previews: some View {
        TunerScreen()
    }
}
