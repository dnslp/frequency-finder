//
//  SharedAudioManager.swift
//  FrequencyFinder
//
//  Created by David Nyman on 8/9/25.
//

import Foundation
import Combine

/// Shared audio manager singleton for use across the app
class SharedAudioManager: ObservableObject {
    static let shared = SharedAudioManager()
    
    @Published private(set) var audioManager = AudioManager()
    @Published var isActive = false
    @Published var currentContext: AudioContext = .none
    
    enum AudioContext {
        case none
        case tuner
        case readingPassage(passageId: String)
        case practice(exerciseId: String)
    }
    
    private init() {
        // Setup observers for AudioManager state
        audioManager.$isListening
            .sink { [weak self] isListening in
                self?.isActive = isListening
            }
            .store(in: &cancellables)
        
        // Forward all AudioManager property changes to trigger UI updates
        audioManager.$frequency
            .sink { _ in /* Trigger objectWillChange */ }
            .store(in: &cancellables)
        
        audioManager.$note
            .sink { _ in /* Trigger objectWillChange */ }
            .store(in: &cancellables)
        
        audioManager.$cents
            .sink { _ in /* Trigger objectWillChange */ }
            .store(in: &cancellables)
        
        audioManager.$amplitude
            .sink { _ in /* Trigger objectWillChange */ }
            .store(in: &cancellables)
        
        audioManager.$debugInfo
            .sink { _ in /* Trigger objectWillChange */ }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Session Control
    
    func startSession(context: AudioContext) {
        guard !isActive else {
            print("⚠️ SharedAudioManager: Session already active for context: \(currentContext)")
            return
        }
        
        print("🎤 SharedAudioManager: Starting session for context: \(context)")
        currentContext = context
        audioManager.tuningSession.startNewSession()
        audioManager.startListening()
    }
    
    func stopSession() {
        guard isActive else {
            print("⚠️ SharedAudioManager: No active session to stop")
            return
        }
        
        print("🎤 SharedAudioManager: Stopping session for context: \(currentContext)")
        audioManager.stopListening()
        audioManager.tuningSession.stopSession()
        currentContext = .none
    }
    
    func switchContext(_ newContext: AudioContext) {
        if isActive {
            print("🎤 SharedAudioManager: Switching context from \(currentContext) to \(newContext)")
            currentContext = newContext
            // Keep the session running but update context
        }
    }
    
    // MARK: - Convenience Methods for Reading Passages
    
    func startReadingPassageSession(passageId: String) {
        startSession(context: .readingPassage(passageId: passageId))
    }
    
    func startPracticeSession(exerciseId: String) {
        startSession(context: .practice(exerciseId: exerciseId))
    }
    
    // MARK: - Data Access
    
    var currentPitchData: (frequency: Float, note: String, cents: Float, amplitude: Float) {
        return (
            frequency: audioManager.frequency,
            note: audioManager.note,
            cents: audioManager.cents,
            amplitude: audioManager.amplitude
        )
    }
    
    var sessionStatistics: (duration: TimeInterval, pitchCount: Int, averageFrequency: Float, mostCommonNote: String) {
        let session = audioManager.tuningSession
        return (
            duration: session.sessionDuration,
            pitchCount: session.pitchHistory.count,
            averageFrequency: session.averageFrequency,
            mostCommonNote: session.mostCommonNote
        )
    }
    
    func exportSessionData() -> TuningSession {
        return audioManager.tuningSession
    }
}