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
        var loadedProfile = Self.loadProfileFromDiskStatic()
        if var profile = loadedProfile {
            // If the app version or device model is missing (e.g., for existing users), update it.
            if profile.appVersion == nil {
                profile.appVersion = Self.getAppVersion()
            }
            if profile.deviceModel == nil {
                profile.deviceModel = Self.getDeviceModel()
            }
            loadedProfile = profile
        }

        self.currentProfile = loadedProfile ?? UserProfileManager.createDefaultProfile()
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Save the profile if it's new or has been updated.
        if loadedProfile == nil || self.currentProfile.appVersion != Self.getAppVersion() || self.currentProfile.deviceModel != Self.getDeviceModel() {
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
        currentProfile.analytics.streakDays = calculateStreak()
    }

    func calculateStreak() -> Int {
        guard !currentProfile.sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sortedSessions = currentProfile.sessions.sorted { $0.timestamp > $1.timestamp }

        var streak = 0
        var lastStreakDate: Date?

        let uniqueDays = Set(sortedSessions.map { calendar.startOfDay(for: $0.timestamp) })
        let sortedUniqueDays = Array(uniqueDays).sorted { $0 > $1 }

        for day in sortedUniqueDays {
            if let lastDate = lastStreakDate {
                let difference = calendar.dateComponents([.day], from: day, to: lastDate).day
                if difference == 1 {
                    streak += 1
                } else if difference == 0 {
                    // Same day, do nothing
                } else {
                    break // Streak is broken
                }
            } else {
                // First session
                if calendar.isDateInToday(day) || calendar.isDateInYesterday(day) {
                    streak = 1
                } else {
                    break // Not recent enough to start a streak
                }
            }
            lastStreakDate = day
        }

        // If the most recent session is not today, and the streak is ongoing,
        // but the last session was yesterday, the streak is still valid.
        if let firstDay = sortedUniqueDays.first, !calendar.isDateInToday(firstDay) {
            // if it wasn't yesterday, the streak is broken
             if !calendar.isDateInYesterday(firstDay) {
                 return 0
             }
        }


        return streak
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
            experienceLevel: nil, // To be set during onboarding
            appVersion: getAppVersion(),
            deviceModel: getDeviceModel(),
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

    // MARK: - Private Helpers

    private static func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
