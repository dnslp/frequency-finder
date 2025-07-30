//
//  PitchTrackerTests.swift
//  FrequencyFinderTests
//
//  Created by David Nyman on 7/28/25.
//

import XCTest
@testable import FrequencyFinder

final class PitchTrackerTests: XCTestCase {
    var pitchTracker: PitchTracker!

    override func setUp() {
        super.setUp()
        pitchTracker = PitchTracker(smoothingFactor: 0.1)
    }

    override func tearDown() {
        pitchTracker = nil
        super.tearDown()
    }

    func testUpdatePitch_UpdatesPitchAndClosestNote() {
        pitchTracker.updatePitch(to: 440.0)
        XCTAssertEqual(pitchTracker.pitch.measurement.value, 440.0)
        XCTAssertEqual(pitchTracker.closestNote.note, .A)
        XCTAssertEqual(pitchTracker.closestNote.octave, 4)
    }

    func testUpdateDeltaCents_CalculatesDeltaCents() {
        pitchTracker.updatePitch(to: 440.0)
        XCTAssertEqual(pitchTracker.deltaCents, 0.0, accuracy: 0.001)

        pitchTracker.updatePitch(to: 450.0)
        XCTAssertNotEqual(pitchTracker.deltaCents, 0.0)
    }

    func testSmoothingFactor_IsConfigurable() {
        let pitchTracker1 = PitchTracker(smoothingFactor: 0.1)
        pitchTracker1.updatePitch(to: 440.0)
        pitchTracker1.updatePitch(to: 450.0)
        let delta1 = pitchTracker1.deltaCents

        let pitchTracker2 = PitchTracker(smoothingFactor: 0.5)
        pitchTracker2.updatePitch(to: 440.0)
        pitchTracker2.updatePitch(to: 450.0)
        let delta2 = pitchTracker2.deltaCents

        XCTAssertNotEqual(delta1, delta2)
    }
}
