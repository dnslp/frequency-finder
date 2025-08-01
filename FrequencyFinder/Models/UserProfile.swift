//
//  UserProfile.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/27/25.
//

import Foundation

// MARK: - Supporting Types

struct OnboardingEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let flowType: FlowType
    let voiceGoal: String?
    let centeringNeed: String?
    let reminderEnabled: Bool
    let reminderTime: Date?
}


enum FlowType: String, Codable, CaseIterable {
    case centering, stretching, both
}

enum SessionType: String, Codable, CaseIterable {
    case centering, stretching, readingAnalysis
}

enum VocalRange: String, Codable, CaseIterable {
    case bass, baritone, tenor, alto, mezzoSoprano, soprano, undefined

    static func from(f0: Double?) -> VocalRange {
        guard let f0 = f0 else { return .undefined }
        switch f0 {
        case ..<82: return .bass
        case 82..<98: return .baritone
        case 98..<165: return .tenor
        case 165..<247: return .alto
        case 247..<349: return .mezzoSoprano
        case 349...: return .soprano
        default: return .undefined
        }
    }
}

enum HeadphoneType: String, Codable {
    case wired, bluetooth, none
}

enum ExperienceLevel: String, Codable {
    case beginner, intermediate, advanced, professional
}

// MARK: - UserProfile

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var createdAt: Date
    var lastActive: Date

    var onboardingHistory: [OnboardingEntry] = []

    // New properties
    var experienceLevel: ExperienceLevel?
    var appVersion: String?
    var deviceModel: String?

    var preferences: UserPreferences
    var sessions: [VoiceSession]

    var calculatedF0: Double?
    var vocalRange: VocalRange = .undefined
    var f0StabilityScore: Double?
    var pitchRange: ClosedRange<Double>?

    var audioState: AppAudioState
    var analytics: UsageStats

    // Update f₀ and related fields
    mutating func recalculateF0() {
        let f0s = sessions
            .filter { !$0.isDeleted && ($0.type == .readingAnalysis || $0.type == .centering) }
            .compactMap { $0.medianF0 }

        calculatedF0 = f0s.median()
        vocalRange = VocalRange.from(f0: calculatedF0)
        f0StabilityScore = f0s.standardDeviation()
        pitchRange = sessions.filter { !$0.isDeleted }.flatMap { $0.pitchSamples }.range()
    }
}

// MARK: - Preferences, Sessions, Analytics, Audio State

struct UserPreferences: Codable {
    var flowType: FlowType
    var reminderEnabled: Bool
    var preferredReminderTime: Date?
    var voiceGoal: String?
    var centeringNeed: String?
    var preferredLanguage: String
    var textSizeScale: Double
    var colorSchemePreference: String
}

struct VoiceSession: Codable, Identifiable {
    let id: UUID
    let type: SessionType
    let timestamp: Date
    let duration: TimeInterval
    let pitchSamples: [Double]
    let medianF0: Double?
    let meanF0: Double?
    let minF0: Double?
    let maxF0: Double?
    let stdevF0: Double?
    let notes: String?
    var isDeleted: Bool
    var deletionRationale: String?

    init(type: SessionType, pitchSamples: [Double], duration: TimeInterval, notes: String? = nil, isDeleted: Bool = false, deletionRationale: String? = nil) {
        self.id = UUID()
        self.type = type
        self.timestamp = Date()
        self.duration = duration
        self.pitchSamples = pitchSamples
        self.isDeleted = isDeleted
        self.deletionRationale = deletionRationale
        self.notes = notes

        let statsCalculator = StatisticsCalculator()
        if let stats = statsCalculator.calculateStatistics(for: pitchSamples) {
            self.minF0 = stats.min
            self.maxF0 = stats.max
            self.meanF0 = stats.avg
            self.medianF0 = stats.median
            self.stdevF0 = pitchSamples.standardDeviation()
        } else {
            self.minF0 = nil
            self.maxF0 = nil
            self.meanF0 = nil
            self.medianF0 = nil
            self.stdevF0 = nil
        }
    }
}

struct AppAudioState: Codable {
    var isWearingHeadphones: Bool
    var headphoneType: HeadphoneType
    var isBluetoothConnected: Bool
    var isListeningToAppAudio: Bool
    var isUsingExternalAudio: Bool
}

struct UsageStats: Codable {
    var totalSessionCount: Int
    var totalDuration: TimeInterval
    var lastSessionType: SessionType?
    var streakDays: Int
    var completionRate: Double
    var preferredSessionTimeWindow: String
}

// MARK: - Helper Extensions

extension Array where Element == Double {
    func mean() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    func median() -> Double {
        guard !isEmpty else { return 0 }
        let sorted = self.sorted()
        let mid = count / 2
        return count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    func standardDeviation() -> Double {
        guard count > 1 else { return 0 }
        let mean = self.mean()
        let variance = self.map { pow($0 - mean, 2) }.reduce(0, +) / Double(count - 1)
        return sqrt(variance)
    }

    func range() -> ClosedRange<Double>? {
        guard let min = self.min(), let max = self.max() else { return nil }
        return min...max
    }
}
