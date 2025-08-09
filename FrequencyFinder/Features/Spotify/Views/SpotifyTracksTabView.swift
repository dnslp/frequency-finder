//
//  SpotifyTracksTabView.swift
//  FrequencyFinder
//
//  Spotify top tracks tab view
//

import SwiftUI

struct SpotifyTracksTabView: View {
    let tracks: [SpotifyTrack]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if tracks.isEmpty {
                    SpotifyEmptyStateView(
                        icon: "music.note",
                        title: "No Tracks Found",
                        message: isOffline ? "No cached track data" : "Connect to see your top tracks"
                    )
                } else {
                    List(tracks) { track in
                        SpotifyTrackRowView(track: track)
                            .listRowBackground(Color.spotifyBlack)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.spotifyBlack)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Top Tracks (\\(tracks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    SpotifyOfflineBanner()
                }
            }
        }
    }
}