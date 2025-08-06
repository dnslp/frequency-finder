import SwiftUI

@main
struct FrequencyFinderApp: App {
    @StateObject private var profileManager = UserProfileManager()
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            if profileManager.hasCompletedOnboarding && !showOnboarding {
                TabView {
                    TunerScreen()
                        .tabItem {
                            Label("Tuner", systemImage: "tuningfork")
                        }

                    ProfileView(profileManager: profileManager, spotifyManager: spotifyManager, showOnboarding: $showOnboarding)
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                    ReadingPassageSessionView(profileManager: profileManager)
                        .tabItem {
                            Label("Reading", systemImage: "book")
                        }
                }
            } else {
                OnboardingView(profileManager: profileManager, showOnboarding: $showOnboarding)
                    .onDisappear {
                        showOnboarding = false
                    }
            }
        }
        .onOpenURL { url in
            spotifyManager.scene(UIApplication.shared.connectedScenes.first as! UIWindowScene, openURLContexts: [UIOpenURLContext(url: url)])
        }
    }
}
