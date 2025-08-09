//
//  SpotifyArtistsTabView.swift
//  FrequencyFinder
//
//  Spotify top artists tab view
//

import SwiftUI

struct SpotifyArtistsTabView: View {
    let artists: [SpotifyArtist]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if artists.isEmpty {
                    SpotifyEmptyStateView(
                        icon: "music.mic",
                        title: "No Artists Found",
                        message: isOffline ? "No cached artist data" : "Connect to see your top artists"
                    )
                } else {
                    List(artists) { artist in
                        SpotifyArtistRowView(artist: artist)
                            .listRowBackground(Color.spotifyBlack)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.spotifyBlack)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Top Artists (\\(artists.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    SpotifyOfflineBanner()
                }
            }
        }
    }
}