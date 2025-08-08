//
//  FlexibleSpotifyModels.swift
//  FrequencyFinder
//
//  More flexible Spotify models to handle API variations
//

import Foundation

// MARK: - Flexible Spotify Models for Better API Compatibility

struct FlexibleSpotifyTrack: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int?
    let duration_ms: Int?  // Made optional since some APIs might not include this
    let explicit: Bool?    // Made optional
    let artists: [FlexibleSpotifyArtist]?  // Made optional array
    let album: FlexibleSpotifyAlbum?       // Made optional
    let external_urls: SpotifyExternalUrls?
    
    // Provide sensible defaults
    var safeDuration: Int { duration_ms ?? 0 }
    var isExplicit: Bool { explicit ?? false }
    var safeArtists: [FlexibleSpotifyArtist] { artists ?? [] }
    var safeAlbum: FlexibleSpotifyAlbum { 
        album ?? FlexibleSpotifyAlbum(id: "", name: "Unknown Album", images: nil, release_date: nil)
    }
}

struct FlexibleSpotifyArtist: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int?
    let followers: SpotifyFollowers?
    let genres: [String]?  // Made optional since it might be missing
    let images: [SpotifyImage]?
    let external_urls: SpotifyExternalUrls?
    
    // Provide sensible defaults
    var safeGenres: [String] { genres ?? [] }
}

struct FlexibleSpotifyAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    let release_date: String?
}

struct FlexibleSpotifyPlayHistory: Codable, Identifiable {
    let track: FlexibleSpotifyTrack
    let played_at: String
    let context: FlexibleSpotifyContext?
    
    var id: String { 
        // Create a safer ID that handles potential missing data
        let trackId = track.id.isEmpty ? "unknown" : track.id
        let playTime = played_at.isEmpty ? UUID().uuidString : played_at
        return trackId + playTime 
    }
}

struct FlexibleSpotifyContext: Codable {
    let type: String?  // Made optional
    let href: String?
    let external_urls: SpotifyExternalUrls?
    
    var safeType: String { type ?? "unknown" }
}

struct FlexibleSpotifyRecentlyPlayedResponse: Codable {
    let items: [FlexibleSpotifyPlayHistory]?  // Made optional to handle empty responses
    let cursors: SpotifyCursors?
    
    var safeItems: [FlexibleSpotifyPlayHistory] { items ?? [] }
}

struct FlexibleSpotifyTopItemsResponse<T: Codable>: Codable {
    let items: [T]?  // Made optional
    let total: Int?  // Made optional
    let limit: Int?  // Made optional
    let offset: Int?  // Made optional
    
    var safeItems: [T] { items ?? [] }
    var safeTotal: Int { total ?? 0 }
}

// MARK: - Conversion Extensions

extension FlexibleSpotifyTrack {
    // Convert to the original SpotifyTrack model for compatibility
    func toSpotifyTrack() -> SpotifyTrack? {
        guard let album = self.album,
              let artists = self.artists,
              !artists.isEmpty else {
            print("⚠️ Skipping track '\(name)' due to missing required data")
            return nil
        }
        
        return SpotifyTrack(
            id: id,
            name: name,
            popularity: popularity,
            duration_ms: safeDuration,
            explicit: isExplicit,
            artists: artists.compactMap { $0.toSpotifyArtist() },
            album: SpotifyAlbum(
                id: album.id,
                name: album.name,
                images: album.images,
                release_date: album.release_date
            ),
            external_urls: external_urls
        )
    }
}

extension FlexibleSpotifyArtist {
    func toSpotifyArtist() -> SpotifyArtist? {
        return SpotifyArtist(
            id: id,
            name: name,
            popularity: popularity,
            followers: followers,
            genres: safeGenres,
            images: images,
            external_urls: external_urls
        )
    }
}

extension FlexibleSpotifyPlayHistory {
    func toSpotifyPlayHistory() -> SpotifyPlayHistory? {
        guard let spotifyTrack = track.toSpotifyTrack() else {
            return nil
        }
        
        return SpotifyPlayHistory(
            track: spotifyTrack,
            played_at: played_at,
            context: context?.toSpotifyContext()
        )
    }
}

extension FlexibleSpotifyContext {
    func toSpotifyContext() -> SpotifyContext? {
        return SpotifyContext(
            type: safeType,
            href: href,
            external_urls: external_urls
        )
    }
}