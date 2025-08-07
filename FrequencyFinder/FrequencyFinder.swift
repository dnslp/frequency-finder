import SwiftUI
import ZenPTrack

@main
struct FrequencyFinderApp: App {
  // 2) Annotate the property's type explicitly
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

  @StateObject private var profileManager = UserProfileManager()
  
  // FFT Implementation Testing - Change this to test different implementations
  init() {
    // 🧪 FFT Testing Configuration
    // Switch between .accelerate (new) and .zen (original) for A/B testing
    FFTConfiguration.defaultImplementation = .accelerate
    
    // Enable performance logging to see the difference
    print("🎛️ FFT Implementation: \(FFTConfiguration.defaultImplementation == .accelerate ? "Accelerate Framework" : "Original ZenFFT")")
  }

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
