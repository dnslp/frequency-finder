//
//  SpotifyView.swift
//  FrequencyFinder
//
//  Main Spotify view with authentication and data display
//

import SwiftUI

// MARK: - Spotify Color Extensions
extension Color {
    static let spotifyGreen = Color(red: 29/255, green: 185/255, blue: 84/255) // #1DB954
    static let spotifyBlack = Color(red: 25/255, green: 20/255, blue: 20/255) // #191414
    static let spotifyDarkGray = Color(red: 40/255, green: 40/255, blue: 40/255) // #282828
    static let spotifyMediumGray = Color(red: 83/255, green: 83/255, blue: 83/255) // #535353
    static let spotifyLightGray = Color(red: 179/255, green: 179/255, blue: 179/255) // #B3B3B3
    static let spotifyWhite = Color.white
}

// Gradient combinations for enhanced visual appeal
extension LinearGradient {
    static let spotifyGreenGradient = LinearGradient(
        colors: [Color.spotifyGreen, Color.spotifyGreen.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let spotifyDarkGradient = LinearGradient(
        colors: [Color.spotifyBlack, Color.spotifyDarkGray.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct SpotifyView: View {
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Connection Status Header
                SpotifyConnectionStatusView(manager: spotifyManager)
                
                if !spotifyManager.isAuthenticated && !spotifyManager.hasOfflineData {
                    // Not authenticated and no cached data
                    SpotifyAuthenticationView(manager: spotifyManager)
                        .background(Color.spotifyBlack)
                } else {
                    // Show data (either live or cached)
                    SpotifyDataTabView(manager: spotifyManager, selectedTab: $selectedTab)
                        .background(Color.spotifyBlack)
                }
            }
            .background(Color.spotifyBlack)
            .navigationTitle("Spotify")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.spotifyBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SpotifyToolbarMenu(manager: spotifyManager)
                }
            }
        }
        .onOpenURL { url in
            if url.scheme == "frequencyfinder" {
                spotifyManager.handleCallback(url: url)
            }
        }
    }
}