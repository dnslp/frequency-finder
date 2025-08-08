//
//  PersistentSpotifyView.swift
//  FrequencyFinder
//
//  Enhanced Spotify view with persistent data and offline support
//

import SwiftUI

struct PersistentSpotifyView: View {
    @StateObject private var spotifyManager = UnifiedSpotifyManager()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Connection Status Header
                ConnectionStatusHeader(manager: spotifyManager)
                
                if !spotifyManager.isAuthenticated && !spotifyManager.hasOfflineData {
                    // Not authenticated and no cached data
                    AuthenticationView(manager: spotifyManager)
                } else {
                    // Show data (either live or cached)
                    PersistentSpotifyDataTabView(manager: spotifyManager, selectedTab: $selectedTab)
                }
            }
            .navigationTitle("Spotify")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ToolbarMenu(manager: spotifyManager)
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

// MARK: - Connection Status Header

struct ConnectionStatusHeader: View {
    @ObservedObject var manager: UnifiedSpotifyManager
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if manager.isAuthenticated && manager.syncStatus.canSync {
                Button(action: {
                    manager.forceSync()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync")
                    }
                    .font(.caption)
                }
                .disabled(manager.isLoading)
            }
            
            Text(manager.cacheStatusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
    
    private var statusColor: Color {
        switch manager.syncStatus {
        case .connected: return .green
        case .syncing: return .orange
        case .offline: return .gray
        case .error: return .red
        }
    }
    
    private var statusText: String {
        if manager.isOfflineMode {
            return "Offline Mode - \(manager.cacheStatusText)"
        } else {
            return manager.syncStatus.displayText
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    @ObservedObject var manager: UnifiedSpotifyManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.primary)
                
                Text("Connect to Spotify")
                    .font(.title2)
                    .bold()
                
                Text("Get insights into your music taste with artists, tracks, playlists, and listening history. Data is cached locally for offline viewing!")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            if manager.isLoading {
                ProgressView("Connecting...")
                    .frame(height: 44)
            } else {
                Button("Connect to Spotify") {
                    manager.authenticate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            if let error = manager.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Persistent Spotify Data Tab View

struct PersistentSpotifyDataTabView: View {
    @ObservedObject var manager: UnifiedSpotifyManager
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PersistentProfileTabView(manager: manager)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(0)
            
            PersistentTopArtistsTabView(artists: manager.topArtists, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Artists", systemImage: "music.mic")
                }
                .tag(1)
            
            PersistentTopTracksTabView(tracks: manager.topTracks, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Tracks", systemImage: "music.note")
                }
                .tag(2)
            
            PersistentPlaylistsTabView(playlists: manager.playlists, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }
                .tag(3)
            
            PersistentRecentTabView(recentTracks: manager.recentlyPlayed, isOffline: manager.isOfflineMode)
                .tabItem {
                    Label("Recent", systemImage: "clock")
                }
                .tag(4)
        }
    }
}

// MARK: - Profile Tab

struct PersistentProfileTabView: View {
    @ObservedObject var manager: UnifiedSpotifyManager
    
    var body: some View {
        ScrollView {
            if let profile = manager.userProfile {
                VStack(spacing: 20) {
                    // Offline Mode Banner
                    if manager.isOfflineMode {
                        OfflineBanner()
                    }
                    
                    // Profile Header
                    PersistentProfileHeaderView(profile: profile)
                    
                    // Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        PersistentStatCard(title: "Followers", value: "\(profile.followers?.total ?? 0)")
                        PersistentStatCard(title: "Country", value: profile.country ?? "Unknown")
                        PersistentStatCard(title: "Plan", value: profile.product?.capitalized ?? "Free")
                        PersistentStatCard(title: "Playlists", value: "\(manager.playlists.count)")
                    }
                }
                .padding()
            } else {
                EmptyStateView(
                    icon: "person.circle",
                    title: "No Profile Data",
                    message: "Connect to Spotify to see your profile"
                )
            }
        }
        .refreshable {
            manager.forceSync()
        }
    }
}

// MARK: - Artists Tab

struct PersistentTopArtistsTabView: View {
    let artists: [SpotifyArtist]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if artists.isEmpty {
                    EmptyStateView(
                        icon: "music.mic",
                        title: "No Artists Found",
                        message: isOffline ? "No cached artist data" : "Connect to see your top artists"
                    )
                } else {
                    List(artists) { artist in
                        PersistentArtistRowView(artist: artist)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Top Artists (\(artists.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    OfflineBanner()
                }
            }
        }
    }
}

// MARK: - Tracks Tab

struct PersistentTopTracksTabView: View {
    let tracks: [SpotifyTrack]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if tracks.isEmpty {
                    EmptyStateView(
                        icon: "music.note",
                        title: "No Tracks Found",
                        message: isOffline ? "No cached track data" : "Connect to see your top tracks"
                    )
                } else {
                    List(tracks) { track in
                        PersistentTrackRowView(track: track)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Top Tracks (\(tracks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    OfflineBanner()
                }
            }
        }
    }
}

// MARK: - Playlists Tab

struct PersistentPlaylistsTabView: View {
    let playlists: [SpotifyPlaylist]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if playlists.isEmpty {
                    EmptyStateView(
                        icon: "music.note.list",
                        title: "No Playlists Found",
                        message: isOffline ? "No cached playlist data" : "Connect to see your playlists"
                    )
                } else {
                    List(playlists) { playlist in
                        PersistentPlaylistRowView(playlist: playlist)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Playlists (\(playlists.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    OfflineBanner()
                }
            }
        }
    }
}

// MARK: - Recent Tab

struct PersistentRecentTabView: View {
    let recentTracks: [SpotifyPlayHistory]
    let isOffline: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if recentTracks.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Recent Tracks",
                        message: isOffline ? "No cached recent plays" : "Connect to see recently played"
                    )
                } else {
                    List(recentTracks) { item in
                        PersistentRecentTrackRowView(playHistory: item)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Recent (\(recentTracks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if isOffline {
                    OfflineBanner()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct OfflineBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("Offline Mode - Showing cached data")
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct PersistentProfileHeaderView: View {
    let profile: SpotifyUserProfile
    
    var body: some View {
        HStack {
            if let images = profile.images, let firstImage = images.first {
                AsyncImage(url: URL(string: firstImage.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.display_name ?? "Spotify User")
                    .font(.title2)
                    .bold()
                
                if let email = profile.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let product = profile.product {
                    Text(product.capitalized)
                        .font(.caption)
                        .foregroundColor(product == "premium" ? .green : .secondary)
                }
            }
            
            Spacer()
        }
    }
}

struct PersistentStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct PersistentArtistRowView: View {
    let artist: SpotifyArtist
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: artist.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.headline)
                
                if let popularity = artist.popularity {
                    Text("Popularity: \(popularity)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !artist.genres.isEmpty {
                    Text(artist.genres.prefix(2).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PersistentTrackRowView: View {
    let track: SpotifyTrack
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: track.album.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.headline)
                Text(track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let popularity = track.popularity {
                        Text("Popularity: \(popularity)%")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(formatDuration(track.duration_ms))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ ms: Int) -> String {
        let seconds = ms / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct PersistentPlaylistRowView: View {
    let playlist: SpotifyPlaylist
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: playlist.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.headline)
                
                if let description = playlist.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("\(playlist.tracks.total) tracks • by \(playlist.owner.display_name ?? playlist.owner.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PersistentRecentTrackRowView: View {
    let playHistory: SpotifyPlayHistory
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: playHistory.track.album.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(playHistory.track.name)
                    .font(.headline)
                Text(playHistory.track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatPlayedAt(playHistory.played_at))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatPlayedAt(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Unknown" }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ToolbarMenu: View {
    @ObservedObject var manager: UnifiedSpotifyManager
    
    var body: some View {
        Menu {
            if manager.isAuthenticated {
                Button(action: {
                    manager.forceSync()
                }) {
                    Label("Force Sync", systemImage: "arrow.clockwise")
                }
                .disabled(manager.isLoading)
                
                Divider()
                
                Button(role: .destructive, action: {
                    manager.logout()
                }) {
                    Label("Disconnect", systemImage: "person.slash")
                }
            }
            
            Button(role: .destructive, action: {
                manager.clearAllData()
            }) {
                Label("Clear All Data", systemImage: "trash")
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}