//
//  SpotifyPlaylistsTabView.swift
//  FrequencyFinder
//
//  Spotify playlists tab view
//

import SwiftUI

struct SpotifyPlaylistsTabView: View {
    let playlists: [SpotifyPlaylist]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if playlists.isEmpty {
                    SpotifyEmptyStateView(
                        icon: "music.note.list",
                        title: "No Playlists Found",
                        message: isOffline ? "No cached playlist data" : "Connect to see your playlists"
                    )
                } else {
                    List(playlists) { playlist in
                        SpotifyPlaylistRowView(playlist: playlist)
                            .listRowBackground(Color.spotifyBlack)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.spotifyBlack)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Playlists (\\(playlists.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    SpotifyOfflineBanner()
                }
            }
        }
    }
}