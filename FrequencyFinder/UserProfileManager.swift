//
//  UserProfileManager.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/27/25.
//
import Foundation
import Combine

class UserProfileManager: ObservableObject {
    @Published var currentProfile: UserProfile

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    init() {
        let loadedProfile = Self.loadProfileFromDiskStatic()
        self.currentProfile = loadedProfile ?? UserProfileManager.createDefaultProfile()
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if loadedProfile == nil {
            saveProfileToDisk()
        }
    }


    // MARK: - Public Methods

    func saveProfileToDisk() {
        do {
            let data = try encoder.encode(currentProfile)
            try data.write(to: Self.profileFileURL(), options: [.atomicWrite])
        } catch {
            print("❌ Failed to save profile: \(error.localizedDescription)")
        }
    }

    func addSession(type: SessionType, pitchSamples: [Double], duration: TimeInterval, notes: String? = nil) {
        let session = VoiceSession(type: type, pitchSamples: pitchSamples, duration: duration, notes: notes)
        currentProfile.sessions.append(session)
        updateStats()
        saveProfileToDisk()
    }

    func updateStats() {
        currentProfile.recalculateF0()
        currentProfile.analytics.totalSessionCount = currentProfile.sessions.count
        currentProfile.analytics.totalDuration = currentProfile.sessions.reduce(0) { $0 + $1.duration }
        currentProfile.lastActive = Date()
    }

    func resetProfile() {
        currentProfile = UserProfileManager.createDefaultProfile()
        saveProfileToDisk()
    }

    // MARK: - Static Helpers

    private static func profileFileURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("UserProfile.json")
    }

    static func loadProfileFromDiskStatic() -> UserProfile? {
        do {
            let fileURL = profileFileURL()
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("⚠️ Failed to load profile: \(error.localizedDescription)")
            return nil
        }
    }

    static func createDefaultProfile() -> UserProfile {
        UserProfile(
            id: UUID(),
            createdAt: Date(),
            lastActive: Date(),
            preferences: UserPreferences(
                flowType: .both,
                reminderEnabled: false,
                preferredReminderTime: nil,
                voiceGoal: nil,
                centeringNeed: nil,
                preferredLanguage: Locale.current.identifier,
                textSizeScale: 1.0,
                colorSchemePreference: "system"
            ),
            sessions: [],
            calculatedF0: nil,
            vocalRange: .undefined,
            f0StabilityScore: nil,
            pitchRange: nil,
            audioState: AppAudioState(
                isWearingHeadphones: false,
                headphoneType: .none,
                isBluetoothConnected: false,
                isListeningToAppAudio: false,
                isUsingExternalAudio: false
            ),
            analytics: UsageStats(
                totalSessionCount: 0,
                totalDuration: 0,
                lastSessionType: nil,
                streakDays: 0,
                completionRate: 0,
                preferredSessionTimeWindow: "unspecified"
            )
        )
    }
}
