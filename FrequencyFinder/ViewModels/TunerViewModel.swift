//
//  TunerViewModel.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation
import Combine
import SwiftUI

final class TunerViewModel: ObservableObject {
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

    // MARK: - Properties from View
    @Published var modifierPreference: ModifierPreference
    @Published var selectedTransposition: Int
    @Published private(set) var centsOffset: Double = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        pitchTracker: PitchTracker,
        recorder: Recorder = Recorder(),
        statisticsCalculator: StatisticsCalculator = StatisticsCalculator(),
        amplitude: Double = 0.0,
        harmonics: [Double]? = nil,
        modifierPreference: ModifierPreference = .preferSharps,
        selectedTransposition: Int = 0
    ) {
        self.pitchTracker = pitchTracker
        self.recorder = recorder
        self.statisticsCalculator = statisticsCalculator

        self.amplitude = amplitude
        self.harmonics = harmonics ?? (1...7).map { Double($0) * pitchTracker.pitch.measurement.value }

        self.modifierPreference = modifierPreference
        self.selectedTransposition = selectedTransposition

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

        // Timer to update centsOffset
        Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.centsOffset = self?.deltaCents ?? 0
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties for View
    var match: ScaleNote.Match {
        closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    var targetFrequencyString: String {
        String(format: "%.1f Hz", match.frequency.measurement.value)
    }

    var actualFrequencyString: String {
        String(format: "%.1f Hz", pitch.measurement.value)
    }

    var noteNameString: String {
        let names = match.note.names
        if names.count > 1 {
            return modifierPreference == .preferSharps ? names[0] : names[1]
        }
        return names[0]
    }

    var octave: Int {
        match.octave
    }

    var harmonicsString: String {
        "\(harmonics.map { String(format: "%.1f", $0) }.joined(separator: ", "))"
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
