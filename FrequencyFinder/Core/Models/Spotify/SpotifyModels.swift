//
//  SpotifyModels.swift
//  FrequencyFinder
//
//  Consolidated Spotify API models for better organization
//

import Foundation

// MARK: - Core Spotify Models

struct SpotifyUserProfile: Codable {
    let id: String
    let display_name: String?
    let email: String?
    let followers: SpotifyFollowers?
    let images: [SpotifyImage]?
    let country: String?
    let product: String?
}

struct SpotifyFollowers: Codable {
    let total: Int
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyArtist: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int?
    let followers: SpotifyFollowers?
    let genres: [String]
    let images: [SpotifyImage]?
    let external_urls: SpotifyExternalUrls?
}

struct SpotifyTrack: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int?
    let duration_ms: Int
    let explicit: Bool
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let external_urls: SpotifyExternalUrls?
}

struct SpotifyAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    let release_date: String?
}

struct SpotifyPlaylist: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let isPublic: Bool?
    let collaborative: Bool
    let tracks: SpotifyPlaylistTracks
    let images: [SpotifyImage]?
    let owner: SpotifyPlaylistOwner
    let external_urls: SpotifyExternalUrls?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, collaborative, tracks, images, owner, external_urls
        case isPublic = "public"
    }
}

struct SpotifyPlaylistTracks: Codable {
    let total: Int
}

struct SpotifyPlaylistOwner: Codable {
    let id: String
    let display_name: String?
}

struct SpotifyPlayHistory: Codable, Identifiable {
    let track: SpotifyTrack
    let played_at: String
    let context: SpotifyContext?
    
    var id: String { track.id + played_at }
}

struct SpotifyContext: Codable {
    let type: String
    let href: String?
    let external_urls: SpotifyExternalUrls?
}

struct SpotifyExternalUrls: Codable {
    let spotify: String?
}

// MARK: - API Response Models

struct SpotifyTopItemsResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let limit: Int
    let offset: Int
}

struct SpotifyPlaylistsResponse: Codable {
    let items: [SpotifyPlaylist]
    let total: Int
    let limit: Int
    let offset: Int
}

struct SpotifyRecentlyPlayedResponse: Codable {
    let items: [SpotifyPlayHistory]
    let cursors: SpotifyCursors?
}

struct SpotifyCursors: Codable {
    let after: String?
    let before: String?
}

// MARK: - Authentication Models

struct SpotifyTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
}

struct SpotifyErrorResponse: Codable {
    let error: String
    let error_description: String?
}

// MARK: - Token Data Storage Model

struct SpotifyTokenData: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    let scopes: [String]
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
    
    var isExpiringSoon: Bool {
        let fiveMinutesFromNow = Date().addingTimeInterval(5 * 60)
        return fiveMinutesFromNow >= expiresAt
    }
}