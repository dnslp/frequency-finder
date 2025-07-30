//
//  TunerData.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation
import Combine

final class TunerData: ObservableObject {
    // MARK: - Components
    let pitchTracker: PitchTracker
    let recorder: Recorder
    let statisticsCalculator: StatisticsCalculator

    // MARK: - Published Properties from Components
    @Published var pitch: Frequency
    @Published var closestNote: ScaleNote.Match
    @Published var deltaCents: Double
    @Published var isRecording: Bool
    @Published var recordedPitches: [Double]

    // MARK: - Other Properties
    @Published var amplitude: Double
    @Published var harmonics: [Double]

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        pitch: Double = 440,
        amplitude: Double = 0.0,
        harmonics: [Double]? = nil,
        smoothingFactor: Double = 0.1
    ) {
        self.pitchTracker = PitchTracker(pitch: pitch, smoothingFactor: smoothingFactor)
        self.recorder = Recorder()
        self.statisticsCalculator = StatisticsCalculator()

        self.amplitude = amplitude
        self.harmonics = harmonics ?? (1...7).map { Double($0) * pitch }

        // Initialize published properties from components
        self.pitch = pitchTracker.pitch
        self.closestNote = pitchTracker.closestNote
        self.deltaCents = pitchTracker.deltaCents
        self.isRecording = recorder.isRecording
        self.recordedPitches = recorder.recordedPitches

        // Set up subscriptions to update published properties
        pitchTracker.$pitch.assign(to: &$pitch)
        pitchTracker.$closestNote.assign(to: &$closestNote)
        pitchTracker.$deltaCents.assign(to: &$deltaCents)
        recorder.$isRecording.assign(to: &$isRecording)
        recorder.$recordedPitches.assign(to: &$recordedPitches)
    }

    // MARK: - Method Delegation
    func updatePitch(to newPitch: Double) {
        pitchTracker.updatePitch(to: newPitch)
    }

    func startRecording() {
        recorder.startRecording()
    }

    func stopRecording() {
        recorder.stopRecording()
    }

    func addPitch(_ pitch: Double) {
        recorder.addPitch(pitch)
    }

    func clearRecording() {
        recorder.clearRecording()
    }

    func calculateStatistics() -> (min: Double, max: Double, avg: Double, median: Double)? {
        statisticsCalculator.calculateStatistics(for: recorder.recordedPitches)
    }
}
