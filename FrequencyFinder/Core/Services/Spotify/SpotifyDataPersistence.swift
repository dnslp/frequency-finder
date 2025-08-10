//
//  SpotifyDataPersistence.swift
//  FrequencyFinder
//
//  Unified Spotify data persistence with token refresh and offline caching
//

import Foundation
import Combine

// MARK: - Cached Data Models

struct CachedSpotifyData: Codable {
    let profile: SpotifyUserProfile?
    let topArtists: [SpotifyArtist]
    let topTracks: [SpotifyTrack]
    let playlists: [SpotifyPlaylist]
    let recentlyPlayed: [SpotifyPlayHistory]
    let lastUpdated: Date
    let cacheVersion: String
    
    init(profile: SpotifyUserProfile? = nil,
         topArtists: [SpotifyArtist] = [],
         topTracks: [SpotifyTrack] = [],
         playlists: [SpotifyPlaylist] = [],
         recentlyPlayed: [SpotifyPlayHistory] = []) {
        self.profile = profile
        self.topArtists = topArtists
        self.topTracks = topTracks
        self.playlists = playlists
        self.recentlyPlayed = recentlyPlayed
        self.lastUpdated = Date()
        self.cacheVersion = "1.0"
    }
}

// MARK: - Spotify Data Persistence Service

class SpotifyDataPersistence: ObservableObject {
    @Published var cachedData: CachedSpotifyData?
    @Published var isDataAvailable: Bool = false
    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false
    @Published var syncError: String?
    
    private let userDefaults = UserDefaults.standard
    private let dataKey = "spotify_cached_data"
    
    private let cacheExpirationInterval: TimeInterval = 6 * 60 * 60 // 6 hours
    private let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours
    
    init() {
        loadCachedData()
    }
    
    // MARK: - Cache Management
    
    func loadCachedData() {
        guard let data = userDefaults.data(forKey: dataKey),
              let cached = try? JSONDecoder().decode(CachedSpotifyData.self, from: data) else {
            cachedData = nil
            isDataAvailable = false
            return
        }
        
        cachedData = cached
        lastSyncDate = cached.lastUpdated
        isDataAvailable = true
        
        print("📱 Loaded cached Spotify data from \(cached.lastUpdated.formatted())")
    }
    
    func saveCachedData(_ data: CachedSpotifyData) {
        guard let encoded = try? JSONEncoder().encode(data) else {
            print("❌ Failed to encode Spotify data for caching")
            return
        }
        
        userDefaults.set(encoded, forKey: dataKey)
        cachedData = data
        lastSyncDate = data.lastUpdated
        isDataAvailable = true
        
        print("💾 Saved Spotify data cache updated at \(data.lastUpdated.formatted())")
    }
    
    func clearCachedData() {
        userDefaults.removeObject(forKey: dataKey)
        cachedData = nil
        isDataAvailable = false
        lastSyncDate = nil
        print("🗑️ Cleared Spotify cached data")
    }
    
    // MARK: - Cache Status
    
    var isCacheExpired: Bool {
        guard let cached = cachedData else { return true }
        let ageOfCache = Date().timeIntervalSince(cached.lastUpdated)
        return ageOfCache > cacheExpirationInterval
    }
    
    var isCacheStale: Bool {
        guard let cached = cachedData else { return true }
        let ageOfCache = Date().timeIntervalSince(cached.lastUpdated)
        return ageOfCache > maxCacheAge
    }
    
    var cacheAge: TimeInterval? {
        guard let cached = cachedData else { return nil }
        return Date().timeIntervalSince(cached.lastUpdated)
    }
    
    var cacheStatusText: String {
        guard let age = cacheAge else { return "No cached data" }
        
        if age < 60 {
            return "Just synced"
        } else if age < 3600 {
            let minutes = Int(age / 60)
            return "Synced \(minutes)m ago"
        } else if age < 86400 {
            let hours = Int(age / 3600)
            return "Synced \(hours)h ago"
        } else {
            let days = Int(age / 86400)
            return "Synced \(days)d ago"
        }
    }
    
    // MARK: - Data Update Methods
    
    func updateProfile(_ profile: SpotifyUserProfile) {
        let newData = cachedData ?? CachedSpotifyData()
        let updatedData = CachedSpotifyData(
            profile: profile,
            topArtists: newData.topArtists,
            topTracks: newData.topTracks,
            playlists: newData.playlists,
            recentlyPlayed: newData.recentlyPlayed
        )
        saveCachedData(updatedData)
    }
    
    func updateTopArtists(_ artists: [SpotifyArtist]) {
        let newData = cachedData ?? CachedSpotifyData()
        let updatedData = CachedSpotifyData(
            profile: newData.profile,
            topArtists: artists,
            topTracks: newData.topTracks,
            playlists: newData.playlists,
            recentlyPlayed: newData.recentlyPlayed
        )
        saveCachedData(updatedData)
    }
    
    func updateTopTracks(_ tracks: [SpotifyTrack]) {
        let newData = cachedData ?? CachedSpotifyData()
        let updatedData = CachedSpotifyData(
            profile: newData.profile,
            topArtists: newData.topArtists,
            topTracks: tracks,
            playlists: newData.playlists,
            recentlyPlayed: newData.recentlyPlayed
        )
        saveCachedData(updatedData)
    }
    
    func updatePlaylists(_ playlists: [SpotifyPlaylist]) {
        let newData = cachedData ?? CachedSpotifyData()
        let updatedData = CachedSpotifyData(
            profile: newData.profile,
            topArtists: newData.topArtists,
            topTracks: newData.topTracks,
            playlists: playlists,
            recentlyPlayed: newData.recentlyPlayed
        )
        saveCachedData(updatedData)
    }
    
    func updateRecentlyPlayed(_ recentTracks: [SpotifyPlayHistory]) {
        let newData = cachedData ?? CachedSpotifyData()
        let updatedData = CachedSpotifyData(
            profile: newData.profile,
            topArtists: newData.topArtists,
            topTracks: newData.topTracks,
            playlists: newData.playlists,
            recentlyPlayed: recentTracks
        )
        saveCachedData(updatedData)
    }
    
    func updateAllData(profile: SpotifyUserProfile?,
                      topArtists: [SpotifyArtist]?,
                      topTracks: [SpotifyTrack]?,
                      playlists: [SpotifyPlaylist]?,
                      recentlyPlayed: [SpotifyPlayHistory]?) {
        let currentData = cachedData ?? CachedSpotifyData()
        
        let updatedData = CachedSpotifyData(
            profile: profile ?? currentData.profile,
            topArtists: topArtists ?? currentData.topArtists,
            topTracks: topTracks ?? currentData.topTracks,
            playlists: playlists ?? currentData.playlists,
            recentlyPlayed: recentlyPlayed ?? currentData.recentlyPlayed
        )
        saveCachedData(updatedData)
    }
}