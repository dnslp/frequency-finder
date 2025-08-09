//
//  SpotifyUIComponents.swift
//  FrequencyFinder
//
//  Reusable UI components for Spotify views
//

import SwiftUI

// MARK: - Offline Banner

struct SpotifyOfflineBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            Text("Offline Mode - Showing cached data")
                .font(.caption)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
}

// MARK: - Profile Header

struct SpotifyProfileHeaderView: View {
    let profile: SpotifyUserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: profile.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.spotifyMediumGray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(profile.display_name ?? "Unknown User")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.spotifyWhite)
                
                if let email = profile.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.spotifyLightGray)
                }
            }
        }
    }
}

// MARK: - Stat Card

struct SpotifyStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(.spotifyWhite)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.spotifyLightGray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.spotifyDarkGray.opacity(0.8))
        .cornerRadius(10)
    }
}

// MARK: - Artist Row

struct SpotifyArtistRowView: View {
    let artist: SpotifyArtist
    
    var body: some View {
        HStack(spacing: 12) {
            // Artist Image
            AsyncImage(url: URL(string: artist.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "music.mic")
                    .font(.title2)
                    .foregroundColor(.spotifyMediumGray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.spotifyWhite)
                
                HStack {
                    if let popularity = artist.popularity {
                        Text("\(popularity)% popularity")
                            .font(.caption)
                            .foregroundColor(.spotifyLightGray)
                    }
                    
                    if let followers = artist.followers {
                        Text("• \(followers.total.formatted()) followers")
                            .font(.caption)
                            .foregroundColor(.spotifyLightGray)
                    }
                }
                
                if !artist.genres.isEmpty {
                    Text(artist.genres.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.spotifyLightGray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Track Row

struct SpotifyTrackRowView: View {
    let track: SpotifyTrack
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Image
            AsyncImage(url: URL(string: track.album.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(.spotifyMediumGray)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.spotifyWhite)
                
                Text(track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.spotifyLightGray)
                    .lineLimit(1)
                
                HStack {
                    Text(track.album.name)
                        .font(.caption)
                        .foregroundColor(.spotifyLightGray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatDuration(track.duration_ms))
                        .font(.caption)
                        .foregroundColor(.spotifyLightGray)
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

// MARK: - Playlist Row

struct SpotifyPlaylistRowView: View {
    let playlist: SpotifyPlaylist
    
    var body: some View {
        HStack(spacing: 12) {
            // Playlist Image
            AsyncImage(url: URL(string: playlist.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundColor(.spotifyMediumGray)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.spotifyWhite)
                
                Text("by \(playlist.owner.display_name ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.spotifyLightGray)
                
                Text("\(playlist.tracks.total) tracks")
                    .font(.caption)
                    .foregroundColor(.spotifyLightGray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recent Track Row

struct SpotifyRecentTrackRowView: View {
    let playHistory: SpotifyPlayHistory
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Image
            AsyncImage(url: URL(string: playHistory.track.album.images?.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(.spotifyMediumGray)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playHistory.track.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.spotifyWhite)
                
                Text(playHistory.track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.spotifyLightGray)
                    .lineLimit(1)
                
                Text("Played \(formatPlayTime(playHistory.played_at))")
                    .font(.caption)
                    .foregroundColor(.spotifyLightGray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatPlayTime(_ playedAt: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: playedAt) else { return "recently" }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .named
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Empty State

struct SpotifyEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.spotifyMediumGray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.spotifyWhite)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.spotifyLightGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}