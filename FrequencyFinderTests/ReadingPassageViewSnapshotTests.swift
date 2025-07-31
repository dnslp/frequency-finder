import SnapshotTesting
import SwiftUI
import XCTest
@testable import ZenTuner

final class ReadingPassageViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // diffTool = "ksdiff" // Optional: for local diffing
    }

    func testPassageTextView() {
        let passage = ReadingPassage(
            title: "The Moon’s Mysteries",
            text: "The moon, a celestial beacon, has fascinated humanity since time immemorial."
        )
        let view = PassageTextView(passage: passage)

        assertSnapshot(matching: view, as: .image(layout: .fixed(width: 375, height: 200)))
    }

    func testRecordingControlsView_Start() {
        let view = RecordingControlsView(
            isRecording: .constant(false),
            elapsedTime: .constant(0),
            onToggleRecording: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .fixed(width: 375, height: 150)))
    }

    func testRecordingControlsView_Stop() {
        let view = RecordingControlsView(
            isRecording: .constant(true),
            elapsedTime: .constant(15.5),
            onToggleRecording: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .fixed(width: 375, height: 150)))
    }
}
