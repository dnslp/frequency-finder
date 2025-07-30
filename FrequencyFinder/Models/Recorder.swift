//
//  Recorder.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation

import Combine

/// Manages the recording of pitches.
final class Recorder: ObservableObject {
    /// A Boolean value that indicates whether recording is active.
    @Published var isRecording: Bool = false
    /// The list of recorded pitches in Hz.
    @Published var recordedPitches: [Double] = []

    /// Starts a new recording session.
    func startRecording() {
        isRecording = true
        recordedPitches.removeAll()
    }

    /// Stops the current recording session.
    func stopRecording() {
        isRecording = false
    }

    /// Adds a pitch to the recording if recording is active.
    /// - Parameter pitch: The pitch to add, in Hz.
    func addPitch(_ pitch: Double) {
        if isRecording {
            recordedPitches.append(pitch)
        }
    }

    /// Clears all recorded pitches.
    func clearRecording() {
        recordedPitches.removeAll()
    }
}
