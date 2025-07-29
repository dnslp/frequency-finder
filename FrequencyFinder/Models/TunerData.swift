//
//  TunerData.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation
import Combine

final class TunerData: ObservableObject {
    // MARK: - Published Properties
    @Published var pitch: Frequency
    @Published var closestNote: ScaleNote.Match
    @Published var amplitude: Double
    @Published var harmonics: [Double]

    @Published var isRecording: Bool = false
    @Published var recordedPitches: [Double] = []

    @Published var deltaCents: Double = 0.0
    private let smoothingFactor: Double = 0.1

    // MARK: - Init
    init(pitch: Double = 440, amplitude: Double = 0.0, harmonics: [Double]? = nil) {
        let freq = Frequency(floatLiteral: pitch)
        self.pitch = freq
        self.closestNote = ScaleNote.closestNote(to: freq)
        self.amplitude = amplitude
        self.harmonics = harmonics ?? (1...7).map { Double($0) * pitch }
    }

    // MARK: - Frequency Updates
    func updatePitch(to newPitch: Double) {
        pitch = Frequency(floatLiteral: newPitch)
        closestNote = ScaleNote.closestNote(to: pitch)
        updateDeltaCents()
    }

    func updateDeltaCents() {
        let actual = pitch.measurement.value
        let target = closestNote.frequency.measurement.value
        guard actual > 0, target > 0 else {
            deltaCents = 0
            return
        }
        let rawCents = 1200 * log2(actual / target)
        deltaCents = deltaCents * (1 - smoothingFactor) + rawCents * smoothingFactor
    }

    // MARK: - Recording
    func startRecording() {
        isRecording = true
        recordedPitches.removeAll()
    }

    func stopRecording() {
        isRecording = false
    }

    func addPitch(_ pitch: Double) {
        if isRecording {
            recordedPitches.append(pitch)
        }
    }

    func clearRecording() {
        recordedPitches.removeAll()
    }

    // MARK: - Statistics
    func calculateStatistics() -> (min: Double, max: Double, avg: Double, median: Double)? {
        guard !recordedPitches.isEmpty else { return nil }

        let sorted = recordedPitches.sorted()
        let count = sorted.count
        let avg = sorted.reduce(0, +) / Double(count)
        let median: Double
        if count % 2 == 0 {
            median = (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            median = sorted[count / 2]
        }

        return (sorted.first ?? 0, sorted.last ?? 0, avg, median)
    }
}
