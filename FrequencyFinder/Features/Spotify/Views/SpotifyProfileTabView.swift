//
//  SpotifyProfileTabView.swift
//  FrequencyFinder
//
//  Spotify user profile tab view
//

import SwiftUI

struct SpotifyProfileTabView: View {
    @ObservedObject var manager: SpotifyManager
    
    var body: some View {
        ScrollView {
            if let profile = manager.userProfile {
                VStack(spacing: 20) {
                    // Offline Mode Banner
                    if manager.isOfflineMode {
                        SpotifyOfflineBanner()
                    }
                    
                    // Profile Header
                    SpotifyProfileHeaderView(profile: profile)
                    
                    // Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        SpotifyStatCard(title: "Followers", value: "\(profile.followers?.total ?? 0)")
                        SpotifyStatCard(title: "Country", value: profile.country ?? "Unknown")
                        SpotifyStatCard(title: "Plan", value: profile.product?.capitalized ?? "Free")
                        SpotifyStatCard(title: "Playlists", value: "\(manager.playlists.count)")
                    }
                }
                .padding()
            } else {
                SpotifyEmptyStateView(
                    icon: "person.circle",
                    title: "No Profile Data",
                    message: "Connect to Spotify to see your profile"
                )
            }
        }
        .refreshable {
            manager.forceSync()
        }
        .background(Color.spotifyBlack)
    }
}