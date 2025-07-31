import SwiftUI

@main
struct FrequencyFinderApp: App {
    @StateObject private var profileManager = UserProfileManager()
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            if profileManager.hasCompletedOnboarding && !showOnboarding {
                TabView {
                    TunerScreen()
                        .tabItem {
                            Label("Tuner", systemImage: "tuningfork")
                        }

                    ProfileView(profileManager: profileManager, showOnboarding: $showOnboarding)
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                    ReadingPassageSessionView(profileManager: profileManager)
                        .tabItem {
                            Label("Reading", systemImage: "book")
                        }
                    SessionHistoryView(profileManager: profileManager)
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                }
            } else {
                OnboardingView(profileManager: profileManager, showOnboarding: $showOnboarding)
                    .onDisappear {
                        showOnboarding = false
                    }
            }
        }
    }
}
