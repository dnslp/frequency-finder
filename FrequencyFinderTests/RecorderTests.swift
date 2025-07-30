//
//  RecorderTests.swift
//  FrequencyFinderTests
//
//  Created by David Nyman on 7/28/25.
//

import XCTest
@testable import FrequencyFinder

final class RecorderTests: XCTestCase {
    var recorder: Recorder!

    override func setUp() {
        super.setUp()
        recorder = Recorder()
    }

    override func tearDown() {
        recorder = nil
        super.tearDown()
    }

    func testStartRecording_SetsIsRecordingToTrue() {
        recorder.startRecording()
        XCTAssertTrue(recorder.isRecording)
    }

    func testStopRecording_SetsIsRecordingToFalse() {
        recorder.startRecording()
        recorder.stopRecording()
        XCTAssertFalse(recorder.isRecording)
    }

    func testAddPitch_WhenRecording_AddsPitchToRecordedPitches() {
        recorder.startRecording()
        recorder.addPitch(100.0)
        XCTAssertEqual(recorder.recordedPitches, [100.0])
    }

    func testAddPitch_WhenNotRecording_DoesNotAddPitchToRecordedPitches() {
        recorder.addPitch(100.0)
        XCTAssertTrue(recorder.recordedPitches.isEmpty)
    }

    func testClearRecording_RemovesAllPitchesFromRecordedPitches() {
        recorder.startRecording()
        recorder.addPitch(100.0)
        recorder.addPitch(200.0)
        recorder.clearRecording()
        XCTAssertTrue(recorder.recordedPitches.isEmpty)
    }
}
