//
//  ProfileView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/27/25.
//


import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager: UserProfileManager
      @Binding var showOnboarding: Bool

    var profile: UserProfile {
        profileManager.currentProfile
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("🎯 Usage")) {
                    Picker("Flow Type", selection: $profileManager.currentProfile.preferences.flowType) {
                        ForEach(FlowType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized)
                        }
                    }

                    Text("Voice Goal: \(profile.preferences.voiceGoal ?? "—")")
                    Text("Centering Need: \(profile.preferences.centeringNeed ?? "—")")
                }

                Section(header: Text("📊 Metrics")) {
                    Text("f₀: \(profile.calculatedF0?.rounded() ?? 0, specifier: "%.1f") Hz")
                    Text("Vocal Range: \(profile.vocalRange.rawValue.capitalized)")
                    Text("Pitch Stability: ±\(profile.f0StabilityScore?.rounded() ?? 0, specifier: "%.1f") Hz")
                    if let range = profile.pitchRange {
                        Text("Pitch Range: \(range.lowerBound, specifier: "%.1f")–\(range.upperBound, specifier: "%.1f") Hz")
                    }
                }

                Section(header: Text("🎙️ Sessions")) {
                    NavigationLink(destination: SessionHistoryView(profileManager: profileManager)) {
                        VStack(alignment: .leading) {
                            Text("Total Sessions: \(profile.analytics.totalSessionCount)")
                            Text("Total Time: \(formatTime(profile.analytics.totalDuration))")
                        }
                    }
                }
                
                Section(header: Text("📊 f₀ Trend")) {
                    F0TrendChartView(profileManager: profileManager)
                }


                Section(header: Text("⏰ Reminders")) {
                    Toggle("Enable Reminder", isOn: $profileManager.currentProfile.preferences.reminderEnabled)

                    if profile.preferences.reminderEnabled {
                        if #available(watchOS 10.0, *) {
                            DatePicker("Reminder Time", selection: Binding(
                                get: { profileManager.currentProfile.preferences.preferredReminderTime ?? Date() },
                                set: { profileManager.currentProfile.preferences.preferredReminderTime = $0 }
                            ), displayedComponents: .hourAndMinute)
                        } else {
                            Text("Reminder time not available on this version of watchOS.")
                        }
                    }
                }

                Section(header: Text("🔊 Audio State")) {
                    Text("Wearing Headphones: \(profile.audioState.isWearingHeadphones ? "Yes" : "No")")
                    Text("Type: \(profile.audioState.headphoneType.rawValue.capitalized)")
                    Text("Bluetooth: \(profile.audioState.isBluetoothConnected ? "Yes" : "No")")
                    Text("App Audio Playing: \(profile.audioState.isListeningToAppAudio ? "Yes" : "No")")
                    Text("External Audio Playing: \(profile.audioState.isUsingExternalAudio ? "Yes" : "No")")
                }
                Section(header: Text("🗓️ Onboarding History")) {
                    ForEach(profile.onboardingHistory.sorted(by: { $0.date > $1.date })) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, style: .date)
                                .font(.caption)

                            Text("Flow: \(entry.flowType.rawValue.capitalized)")
                            if let goal = entry.voiceGoal, !goal.isEmpty {
                                Text("Goal: \(goal)")
                            }
                            if let need = entry.centeringNeed, !need.isEmpty {
                                Text("Centering: \(need)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section {
                    Button("Run Onboarding Again") {
                        profileManager.hasCompletedOnboarding = false
                        showOnboarding = true
                    }
                }


                Section {
                    Button(role: .destructive) {
                        profileManager.resetProfile()
                    } label: {
                        Text("Reset Profile")
                    }
                }
            }
            .navigationTitle("User Profile")
        }
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return "\(minutes)m \(sec)s"
    }
}
