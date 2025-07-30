//
//  StatisticsCalculatorTests.swift
//  FrequencyFinderTests
//
//  Created by David Nyman on 7/28/25.
//

import XCTest
@testable import FrequencyFinder

final class StatisticsCalculatorTests: XCTestCase {
    var calculator: StatisticsCalculator!

    override func setUp() {
        super.setUp()
        calculator = StatisticsCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    func testCalculateStatistics_WithEmptyPitches_ReturnsNil() {
        let pitches: [Double] = []
        let stats = calculator.calculateStatistics(for: pitches)
        XCTAssertNil(stats)
    }

    func testCalculateStatistics_WithOddNumberOfPitches_ReturnsCorrectStatistics() {
        let pitches = [100.0, 200.0, 300.0, 400.0, 500.0]
        let stats = calculator.calculateStatistics(for: pitches)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.min, 100.0)
        XCTAssertEqual(stats?.max, 500.0)
        XCTAssertEqual(stats?.avg, 300.0)
        XCTAssertEqual(stats?.median, 300.0)
    }

    func testCalculateStatistics_WithEvenNumberOfPitches_ReturnsCorrectStatistics() {
        let pitches = [100.0, 200.0, 300.0, 400.0]
        let stats = calculator.calculateStatistics(for: pitches)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.min, 100.0)
        XCTAssertEqual(stats?.max, 400.0)
        XCTAssertEqual(stats?.avg, 250.0)
        XCTAssertEqual(stats?.median, 250.0)
    }
}
