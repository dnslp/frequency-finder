//
//  SpotifyManager.swift
//  FrequencyFinder
//
//  Unified Spotify manager coordinating auth, networking, and persistence
//

import SwiftUI
import Combine

enum SpotifySyncStatus {
    case idle
    case syncing
    case success
    case error(String)
    case partialFailure([String])
    
    var displayText: String {
        switch self {
        case .idle: return "Ready to sync"
        case .syncing: return "Syncing..."
        case .success: return "Sync completed"
        case .error(let msg): return "Error: \(msg)"
        case .partialFailure(let errors): return "Partial sync (\(errors.count) errors)"
        }
    }
    
    var canSync: Bool {
        switch self {
        case .idle, .success, .error, .partialFailure: return true
        case .syncing: return false
        }
    }
}

class SpotifyManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: SpotifySyncStatus = .idle
    
    // Data
    @Published var userProfile: SpotifyUserProfile?
    @Published var topArtists: [SpotifyArtist] = []
    @Published var topTracks: [SpotifyTrack] = []
    @Published var playlists: [SpotifyPlaylist] = []
    @Published var recentlyPlayed: [SpotifyPlayHistory] = []
    
    // Services
    private let auth = SpotifyAuth()
    private let networking: SpotifyNetworking
    private let persistence = SpotifyDataPersistence()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        networking = SpotifyNetworking(auth: auth)
        setupBindings()
        loadCachedData()
    }
    
    private func setupBindings() {
        // Bind authentication state
        auth.$isAuthenticated
            .assign(to: &$isAuthenticated)
        
        // Auto-sync data when authentication succeeds
        auth.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                print("🔐 Auth state changed: \(isAuthenticated)")
                if isAuthenticated {
                    print("🎯 Triggering auto-sync after authentication...")
                    self?.syncAllData()
                }
            }
            .store(in: &cancellables)
        
        auth.$errorMessage
            .assign(to: &$errorMessage)
        
        // Load cached data when persistence updates
        persistence.$cachedData
            .compactMap { $0 }
            .sink { [weak self] cachedData in
                self?.loadDataFromCache(cachedData)
            }
            .store(in: &cancellables)
    }
    
    private func loadCachedData() {
        guard let cachedData = persistence.cachedData else { return }
        loadDataFromCache(cachedData)
    }
    
    private func loadDataFromCache(_ cachedData: CachedSpotifyData) {
        print("📱 Loading data from cache - Profile: \(cachedData.profile?.display_name ?? "nil"), Artists: \(cachedData.topArtists.count), Tracks: \(cachedData.topTracks.count)")
        userProfile = cachedData.profile
        topArtists = cachedData.topArtists
        topTracks = cachedData.topTracks
        playlists = cachedData.playlists
        recentlyPlayed = cachedData.recentlyPlayed
    }
    
    // MARK: - Authentication
    
    func authenticate() {
        let scopes = [
            "user-read-private",
            "user-read-email",
            "user-top-read",
            "user-read-recently-played",
            "playlist-read-private",
            "playlist-read-collaborative"
        ]
        
        auth.authenticate(scopes: scopes)
    }
    
    func handleCallback(url: URL) {
        auth.handleCallback(url: url)
    }
    
    func logout() {
        auth.logout()
        clearAllData()
    }
    
    // MARK: - Data Syncing
    
    func syncAllData() {
        print("🔄 syncAllData called - isAuthenticated: \(auth.isAuthenticated), canSync: \(syncStatus.canSync)")
        guard auth.isAuthenticated, syncStatus.canSync else { 
            print("❌ Sync guard failed - isAuthenticated: \(auth.isAuthenticated), canSync: \(syncStatus.canSync)")
            return 
        }
        
        print("✅ Starting Spotify data sync...")
        syncStatus = .syncing
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        var fetchErrors: [String] = []
        
        var newProfile: SpotifyUserProfile?
        var newTopArtists: [SpotifyArtist] = []
        var newTopTracks: [SpotifyTrack] = []
        var newPlaylists: [SpotifyPlaylist] = []
        var newRecentlyPlayed: [SpotifyPlayHistory] = []
        
        // Fetch user profile
        group.enter()
        networking.fetchUserProfile { result in
            defer { group.leave() }
            switch result {
            case .success(let profile):
                print("✅ Profile fetch success: \(profile.display_name ?? "Unknown")")
                newProfile = profile
            case .failure(let error):
                print("❌ Profile fetch failed: \(error.localizedDescription)")
                fetchErrors.append("Profile: \(error.localizedDescription)")
            }
        }
        
        // Fetch top artists
        group.enter()
        networking.fetchTopArtists { result in
            defer { group.leave() }
            switch result {
            case .success(let artists):
                print("✅ Top artists fetch success: \(artists.count) artists")
                newTopArtists = artists
            case .failure(let error):
                print("❌ Top artists fetch failed: \(error.localizedDescription)")
                fetchErrors.append("Top Artists: \(error.localizedDescription)")
            }
        }
        
        // Fetch top tracks
        group.enter()
        networking.fetchTopTracks { result in
            defer { group.leave() }
            switch result {
            case .success(let tracks):
                newTopTracks = tracks
            case .failure(let error):
                fetchErrors.append("Top Tracks: \(error.localizedDescription)")
            }
        }
        
        // Fetch playlists
        group.enter()
        networking.fetchPlaylists { result in
            defer { group.leave() }
            switch result {
            case .success(let playlists):
                newPlaylists = playlists
            case .failure(let error):
                fetchErrors.append("Playlists: \(error.localizedDescription)")
            }
        }
        
        // Fetch recently played
        group.enter()
        networking.fetchRecentlyPlayed { result in
            defer { group.leave() }
            switch result {
            case .success(let recent):
                newRecentlyPlayed = recent
            case .failure(let error):
                fetchErrors.append("Recently Played: \(error.localizedDescription)")
            }
        }
        
        // Handle completion
        group.notify(queue: .main) { [weak self] in
            print("🎉 Sync completed! Profile: \(newProfile?.display_name ?? "nil"), Artists: \(newTopArtists.count), Errors: \(fetchErrors.count)")
            self?.isLoading = false
            
            // Update data even if some requests failed
            self?.userProfile = newProfile ?? self?.userProfile
            self?.topArtists = newTopArtists.isEmpty ? (self?.topArtists ?? []) : newTopArtists
            self?.topTracks = newTopTracks.isEmpty ? (self?.topTracks ?? []) : newTopTracks
            self?.playlists = newPlaylists.isEmpty ? (self?.playlists ?? []) : newPlaylists
            self?.recentlyPlayed = newRecentlyPlayed.isEmpty ? (self?.recentlyPlayed ?? []) : newRecentlyPlayed
            
            // Update cache
            self?.persistence.updateAllData(
                profile: newProfile,
                topArtists: newTopArtists.isEmpty ? nil : newTopArtists,
                topTracks: newTopTracks.isEmpty ? nil : newTopTracks,
                playlists: newPlaylists.isEmpty ? nil : newPlaylists,
                recentlyPlayed: newRecentlyPlayed.isEmpty ? nil : newRecentlyPlayed
            )
            
            // Update sync status
            if fetchErrors.isEmpty {
                self?.syncStatus = .success
            } else if fetchErrors.count < 5 { // Less than total requests failed
                self?.syncStatus = .partialFailure(fetchErrors)
            } else {
                let errorMsg = "All data failed to sync: \(fetchErrors.joined(separator: ", "))"
                self?.syncStatus = .error(errorMsg)
                self?.errorMessage = errorMsg
            }
        }
    }
    
    func forceSync() {
        syncStatus = .idle
        syncAllData()
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        userProfile = nil
        topArtists = []
        topTracks = []
        playlists = []
        recentlyPlayed = []
        persistence.clearCachedData()
        syncStatus = .idle
    }
    
    // MARK: - Computed Properties
    
    var cacheStatusText: String {
        persistence.cacheStatusText
    }
    
    var hasOfflineData: Bool {
        persistence.isDataAvailable
    }
    
    var isOfflineMode: Bool {
        !isAuthenticated && hasOfflineData
    }
}