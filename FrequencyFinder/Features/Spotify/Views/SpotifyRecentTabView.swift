//
//  SpotifyRecentTabView.swift
//  FrequencyFinder
//
//  Spotify recently played tab view
//

import SwiftUI

struct SpotifyRecentTabView: View {
    let recentTracks: [SpotifyPlayHistory]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if recentTracks.isEmpty {
                    SpotifyEmptyStateView(
                        icon: "clock",
                        title: "No Recent Tracks",
                        message: isOffline ? "No cached recent data" : "Connect to see your recently played tracks"
                    )
                } else {
                    List(recentTracks) { playHistory in
                        SpotifyRecentTrackRowView(playHistory: playHistory)
                            .listRowBackground(Color.spotifyBlack)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.spotifyBlack)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Recent (\\(recentTracks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    SpotifyOfflineBanner()
                }
            }
        }
    }
}