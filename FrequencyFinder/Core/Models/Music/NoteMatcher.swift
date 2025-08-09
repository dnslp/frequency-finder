//
//  NoteMatcher.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation

import Darwin.C.math

/// A utility for finding the closest musical note to a given frequency and calculating the delta in cents.
struct NoteMatcher {
    /// Finds the closest note to the specified frequency.
    /// - Parameter frequency: The frequency to match against.
    /// - Returns: The closest note match.
    static func closestNote(to frequency: Frequency) -> ScaleNote.Match {
        // Shift frequency octave to be within range of scale note frequencies.
        var octaveShiftedFrequency = frequency

        while octaveShiftedFrequency > ScaleNote.allCases.last!.frequency {
            octaveShiftedFrequency.shift(byOctaves: -1)
        }

        while octaveShiftedFrequency < ScaleNote.allCases.first!.frequency {
            octaveShiftedFrequency.shift(byOctaves: 1)
        }

        // Find closest note
        let closestNote = ScaleNote.allCases.min(by: { note1, note2 in
            fabsf(note1.frequency.distance(to: octaveShiftedFrequency).cents) <
                fabsf(note2.frequency.distance(to: octaveShiftedFrequency).cents)
        })!

        let octave = max(octaveShiftedFrequency.distanceInOctaves(to: frequency), 0)

        let fastResult = ScaleNote.Match(
            note: closestNote,
            octave: octave,
            distance: closestNote.frequency.distance(to: octaveShiftedFrequency)
        )

        // Fast result can be incorrect at the scale boundary
        guard fastResult.note == .C && fastResult.distance.isFlat ||
                fastResult.note == .B && fastResult.distance.isSharp else
        {
            return fastResult
        }

        var match: ScaleNote.Match?
        for octave in [octave, octave + 1] {
            for note in [ScaleNote.C, .B] {
                let distance = note.frequency.shifted(byOctaves: octave).distance(to: frequency)
                if let match = match, abs(distance.cents) > abs(match.distance.cents) {
                    return match
                } else {
                    match = ScaleNote.Match(
                        note: note,
                        octave: octave,
                        distance: distance
                    )
                }
            }
        }

        assertionFailure("Closest note could not be found")
        return fastResult
    }

    /// Calculates the delta in cents between a pitch and a note, with smoothing.
    /// - Parameters:
    ///   - pitch: The current pitch.
    ///   - closestNote: The closest note to the pitch.
    ///   - smoothingFactor: The smoothing factor to apply.
    ///   - currentDeltaCents: The current delta in cents, used for smoothing.
    /// - Returns: The new delta in cents.
    static func calculateDeltaCents(pitch: Frequency, closestNote: ScaleNote.Match, smoothingFactor: Double, currentDeltaCents: Double) -> Double {
        let actual = pitch.measurement.value
        let target = closestNote.frequency.measurement.value
        guard actual > 0, target > 0 else {
            return 0
        }
        let rawCents = 1200 * log2(actual / target)
        return currentDeltaCents * (1 - smoothingFactor) + rawCents * smoothingFactor
    }
}
