//
//  OnboardingView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/27/25.
//


import SwiftUI

struct OnboardingView: View {
    @ObservedObject var profileManager: UserProfileManager
    @Binding var showOnboarding: Bool
    @State private var step = 0
    @State private var selectedFlow: FlowType = .both
    @State private var voiceGoal = ""
    @State private var centeringNeed = ""
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()

    var body: some View {
        VStack {
            if step == 0 {
                Text("How would you like to use the app?")
                    .font(.title2)
                ForEach(FlowType.allCases, id: \.self) { flow in
                    Button(flow.rawValue.capitalized) {
                        selectedFlow = flow
                        step += 1
                    }
                    .padding()
                }
            } else if step == 1 {
                if selectedFlow == .stretching || selectedFlow == .both {
                    TextField("What’s your voice goal?", text: $voiceGoal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                if selectedFlow == .centering || selectedFlow == .both {
                    Picker("When do you want to feel centered?", selection: $centeringNeed) {
                        Text("Morning").tag("Morning")
                        Text("Evening").tag("Evening")
                        Text("During stress").tag("Stress")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }
                Button("Next") { step += 1 }
            } else if step == 2 {
                Toggle("Enable daily reminder?", isOn: $reminderEnabled)
                    .padding()

                if reminderEnabled {
                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .padding()
                }

                Button("Finish Setup") {
                    // Update preferences
                    profileManager.currentProfile.preferences.flowType = selectedFlow
                    profileManager.currentProfile.preferences.voiceGoal = voiceGoal
                    profileManager.currentProfile.preferences.centeringNeed = centeringNeed
                    profileManager.currentProfile.preferences.reminderEnabled = reminderEnabled
                    profileManager.currentProfile.preferences.preferredReminderTime = reminderEnabled ? reminderTime : nil

                    // Add onboarding entry
                    let entry = OnboardingEntry(
                        id: UUID(),
                        date: Date(),
                        flowType: selectedFlow,
                        voiceGoal: voiceGoal,
                        centeringNeed: centeringNeed,
                        reminderEnabled: reminderEnabled,
                        reminderTime: reminderEnabled ? reminderTime : nil
                    )
                    profileManager.currentProfile.onboardingHistory.append(entry)

                    // Save
                    profileManager.saveProfileToDisk()
                    profileManager.hasCompletedOnboarding = true
                    showOnboarding = false  // ✅ THIS is the fix!
                }


                .padding(.top)
            }
        }
        .padding()
        .animation(.easeInOut, value: step)
    }
}
