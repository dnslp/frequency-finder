import Darwin.C.math
import SwiftUI

/// A note in a twelve-tone equal temperament scale. https://en.wikipedia.org/wiki/Equal_temperament
enum ScaleNote: Int, CaseIterable, Identifiable {
    case C, CSharp_DFlat, D, DSharp_EFlat, E, F, FSharp_GFlat, G, GSharp_AFlat, A, ASharp_BFlat, B

    var id: Int { rawValue }

    /// A note match given an input frequency.
    struct Match: Hashable {
        /// The matched note.
        let note: ScaleNote
        /// The octave of the matched note.
        let octave: Int
        /// The distance between the input frequency and the matched note's defined frequency.
        let distance: Frequency.MusicalDistance

        /// The frequency of the matched note, adjusted by octave.
        var frequency: Frequency { note.frequency.shifted(byOctaves: octave) }

        /// The current note match adjusted for transpositions.
        ///
        /// - parameter transposition: The transposition on which to map the current match.
        ///
        /// - returns: The match mapped to the specified transposition.
        func inTransposition(_ transposition: ScaleNote) -> ScaleNote.Match {
            let transpositionDistanceFromC = transposition.rawValue
            guard transpositionDistanceFromC > 0 else {
                return self
            }

            let currentNoteIndex = note.rawValue
            let allNotes = ScaleNote.allCases
            let noteOffset = (allNotes.count - transpositionDistanceFromC) + currentNoteIndex
            let transposedNoteIndex = noteOffset % allNotes.count
            let transposedNote = allNotes[transposedNoteIndex]
            let octaveShift = (noteOffset > allNotes.count - 1) ? 1 : 0
            return ScaleNote.Match(
                note: transposedNote,
                octave: octave + octaveShift,
                distance: distance
            )
        }
    }


    /// The names for this note.
    var names: [String] {
        switch self {
        case .C:             ["C"]
        case .CSharp_DFlat:  ["C♯", "D♭"]
        case .D:             ["D"]
        case .DSharp_EFlat:  ["D♯", "E♭"]
        case .E:             ["E"]
        case .F:             ["F"]
        case .FSharp_GFlat:  ["F♯", "G♭"]
        case .G:             ["G"]
        case .GSharp_AFlat:  ["G♯", "A♭"]
        case .A:             ["A"]
        case .ASharp_BFlat:  ["A♯", "B♭"]
        case .B:             ["B"]
        }
    }

    /// The frequency for this note at the 0th octave in standard pitch: https://en.wikipedia.org/wiki/Standard_pitch
    var frequency: Frequency {
        switch self {
        case .C:            16.35160
        case .CSharp_DFlat: 17.32391
        case .D:            18.35405
        case .DSharp_EFlat: 19.44544
        case .E:            20.60172
        case .F:            21.82676
        case .FSharp_GFlat: 23.12465
        case .G:            24.49971
        case .GSharp_AFlat: 25.95654
        case .A:            27.5
        case .ASharp_BFlat: 29.13524
        case .B:            30.86771
        }
    }
}
