//
//  PitchTracker.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation

import Combine

/// Handles pitch tracking, note matching, and delta cent calculations.
final class PitchTracker: ObservableObject {
    /// The current pitch in Hz.
    @Published var pitch: Frequency
    /// The closest musical note to the current pitch.
    @Published var closestNote: ScaleNote.Match
    /// The difference between the current pitch and the closest note in cents, with smoothing.
    @Published var deltaCents: Double = 0.0

    private let smoothingFactor: Double

    /// Initializes a new pitch tracker.
    /// - Parameters:
    ///   - pitch: The initial pitch in Hz.
    ///   - smoothingFactor: The factor to use for smoothing delta cent calculations.
    init(pitch: Double = 440, smoothingFactor: Double = 0.1) {
        let freq = Frequency(floatLiteral: pitch)
        self.pitch = freq
        self.closestNote = NoteMatcher.closestNote(to: freq)
        self.smoothingFactor = smoothingFactor
    }

    /// Updates the pitch and recalculates the closest note and delta cents.
    /// - Parameter newPitch: The new pitch in Hz.
    func updatePitch(to newPitch: Double) {
        pitch = Frequency(floatLiteral: newPitch)
        closestNote = NoteMatcher.closestNote(to: pitch)
        updateDeltaCents()
    }

    private func updateDeltaCents() {
        deltaCents = NoteMatcher.calculateDeltaCents(pitch: pitch, closestNote: closestNote, smoothingFactor: smoothingFactor, currentDeltaCents: deltaCents)
    }
}
