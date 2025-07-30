//
//  StatisticsCalculator.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation

/// A utility for calculating statistics on a set of pitches.
final class StatisticsCalculator {
    /// Calculates statistics for a given array of pitches.
    /// - Parameter pitches: An array of pitches in Hz.
    /// - Returns: A tuple containing the minimum, maximum, average, and median pitch, or `nil` if the input array is empty.
    func calculateStatistics(for pitches: [Double]) -> (min: Double, max: Double, avg: Double, median: Double)? {
        guard !pitches.isEmpty else { return nil }

        let sorted = pitches.sorted()
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
