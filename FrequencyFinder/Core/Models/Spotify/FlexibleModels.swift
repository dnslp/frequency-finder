//
//  FlexibleModels.swift
//  FrequencyFinder
//
//  Flexible Spotify models for robust API parsing with optional fields
//

import Foundation

// MARK: - Flexible Spotify Models for Better API Compatibility

struct FlexibleSpotifyTrack: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int?
    let duration_ms: Int?
    let explicit: Bool?
    let artists: [FlexibleSpotifyArtist]?
    let album: FlexibleSpotifyAlbum?
    let external_urls: SpotifyExternalUrls?
    
    // Provide sensible defaults
    var safeDuration: Int { duration_ms ?? 0 }
    var isExplicit: Bool { explicit ?? false }
    var safeArtists: [FlexibleSpotifyArtist] { artists ?? [] }
    var safeAlbum: FlexibleSpotifyAlbum { 
        album ?? FlexibleSpotifyAlbum(id: "", name: "Unknown Album", images: nil, release_date: nil)
    }
    
    // Convert to the standard SpotifyTrack model for compatibility
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

struct FlexibleSpotifyArtist: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int?
    let followers: SpotifyFollowers?
    let genres: [String]?
    let images: [SpotifyImage]?
    let external_urls: SpotifyExternalUrls?
    
    // Provide sensible defaults
    var safeGenres: [String] { genres ?? [] }
    
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

struct FlexibleSpotifyContext: Codable {
    let type: String?
    let href: String?
    let external_urls: SpotifyExternalUrls?
    
    var safeType: String { type ?? "unknown" }
    
    func toSpotifyContext() -> SpotifyContext? {
        return SpotifyContext(
            type: safeType,
            href: href,
            external_urls: external_urls
        )
    }
}

// MARK: - Flexible Response Models

struct FlexibleSpotifyRecentlyPlayedResponse: Codable {
    let items: [FlexibleSpotifyPlayHistory]?
    let cursors: SpotifyCursors?
    
    var safeItems: [FlexibleSpotifyPlayHistory] { items ?? [] }
}

struct FlexibleSpotifyTopItemsResponse<T: Codable>: Codable {
    let items: [T]?
    let total: Int?
    let limit: Int?
    let offset: Int?
    
    var safeItems: [T] { items ?? [] }
    var safeTotal: Int { total ?? 0 }
}