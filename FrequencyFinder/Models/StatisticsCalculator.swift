//
//  StatisticsCalculator.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//

import Foundation

/// A utility for calculating statistics on a set of pitches.
final class StatisticsCalculator {
    /// Calculates statistics for a given array of pitches after removing outliers.
    /// - Parameter pitches: An array of pitches in Hz.
    /// - Returns: A tuple containing the minimum, maximum, average, and median pitch, or `nil` if the input array is empty.
    func calculateStatistics(for pitches: [Double]) -> (min: Double, max: Double, avg: Double, median: Double)? {
        let cleanedPitches = removeOutliers(from: pitches)
        guard !cleanedPitches.isEmpty else { return nil }

        let sorted = cleanedPitches.sorted()
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

    /// Removes outliers from an array of pitches using the IQR method.
    /// - Parameter pitches: An array of pitches in Hz.
    /// - Returns: A new array with outliers removed.
    func removeOutliers(from pitches: [Double]) -> [Double] {
        guard pitches.count >= 4 else { return pitches }

        let sortedPitches = pitches.sorted()
        let q1 = quartile(sortedPitches, percentile: 0.25)
        let q3 = quartile(sortedPitches, percentile: 0.75)
        let iqr = q3 - q1
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr

        return sortedPitches.filter { $0 >= lowerBound && $0 <= upperBound }
    }

    /// Calculates the value at a given percentile in a sorted array.
    /// - Parameters:
    ///   - sortedArray: A sorted array of doubles.
    ///   - percentile: The percentile to calculate (0.0 to 1.0).
    /// - Returns: The value at the given percentile.
    private func quartile(_ sortedArray: [Double], percentile: Double) -> Double {
        let index = percentile * Double(sortedArray.count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))

        if lower == upper {
            return sortedArray[lower]
        } else {
            let remainder = index - Double(lower)
            return sortedArray[lower] * (1.0 - remainder) + sortedArray[upper] * remainder
        }
    }
}
