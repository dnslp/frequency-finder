//
//  SpotifyDataTabView.swift
//  FrequencyFinder
//
//  Main tab view for Spotify data sections
//

import SwiftUI

struct SpotifyDataTabView: View {
    @ObservedObject var manager: SpotifyManager
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SpotifyProfileTabView(manager: manager)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(0)
            
            SpotifyArtistsTabView(artists: manager.topArtists, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Artists", systemImage: "music.mic")
                }
                .tag(1)
            
            SpotifyTracksTabView(tracks: manager.topTracks, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Tracks", systemImage: "music.note")
                }
                .tag(2)
            
            SpotifyPlaylistsTabView(playlists: manager.playlists, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }
                .tag(3)
            
            SpotifyRecentTabView(recentTracks: manager.recentlyPlayed, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Recent", systemImage: "clock")
                }
                .tag(4)
        }
        .background(Color.spotifyBlack)
        .accentColor(.spotifyGreen)
    }
}