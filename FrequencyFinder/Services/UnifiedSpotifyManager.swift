//
//  UnifiedSpotifyManager.swift
//  FrequencyFinder
//
//  Unified Spotify manager with persistence, token refresh, and offline support
//

import SwiftUI
import Combine
import CryptoKit
import Foundation

class UnifiedSpotifyManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .offline
    
    // Data from persistence layer or fresh API calls
    @Published var userProfile: SpotifyUserProfile?
    @Published var topArtists: [SpotifyArtist] = []
    @Published var topTracks: [SpotifyTrack] = []
    @Published var playlists: [SpotifyPlaylist] = []
    @Published var recentlyPlayed: [SpotifyPlayHistory] = []
    
    // MARK: - Private Properties
    private let clientId = "7c5840c8370940a6be5a12336241f464"
    private let redirectURI = "frequencyfinder://callback"
    
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let dataStore = SpotifyDataStore()
    
    // Auto-sync timer
    private var syncTimer: Timer?
    
    // MARK: - Sync Status
    enum SyncStatus {
        case offline           // No token, showing cached data
        case connected        // Valid token, can sync
        case syncing          // Currently fetching fresh data
        case error(String)    // Sync failed, showing cached data
        
        var displayText: String {
            switch self {
            case .offline: return "Offline - Cached data"
            case .connected: return "Connected"
            case .syncing: return "Syncing..."
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var canSync: Bool {
            switch self {
            case .connected: return true
            default: return false
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        setupDataStoreObservers()
        loadInitialData()
        startAutoSyncTimer()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    private func setupDataStoreObservers() {
        // Observe data store changes
        dataStore.$cachedData
            .compactMap { $0 }
            .sink { [weak self] cachedData in
                self?.updatePublishedPropertiesFromCache(cachedData)
            }
            .store(in: &cancellables)
        
        dataStore.$isSyncing
            .sink { [weak self] isSyncing in
                self?.isLoading = isSyncing
            }
            .store(in: &cancellables)
    }
    
    private func updatePublishedPropertiesFromCache(_ cachedData: CachedSpotifyData) {
        userProfile = cachedData.profile
        topArtists = cachedData.topArtists
        topTracks = cachedData.topTracks
        playlists = cachedData.playlists
        recentlyPlayed = cachedData.recentlyPlayed
    }
    
    // MARK: - Initial Data Loading
    private func loadInitialData() {
        // Always load cached data first (for offline viewing)
        dataStore.loadCachedData()
        
        // Check authentication status
        if let tokenData = dataStore.getTokenData() {
            if tokenData.isExpired {
                if let refreshToken = tokenData.refreshToken {
                    print("🔄 Token expired, attempting refresh...")
                    refreshAccessToken(refreshToken: refreshToken)
                } else {
                    print("⚠️ Token expired, no refresh token available")
                    syncStatus = .offline
                    isAuthenticated = false
                }
            } else {
                print("✅ Valid token found")
                isAuthenticated = true
                syncStatus = .connected
                
                // Sync fresh data if cache is expired
                if dataStore.isCacheExpired {
                    syncAllData()
                }
            }
        } else {
            print("❌ No token found")
            syncStatus = .offline
            isAuthenticated = false
        }
    }
    
    // MARK: - Authentication Flow
    func authenticate() {
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        let scopes = [
            "user-read-private",
            "user-read-email",
            "user-top-read",
            "user-read-recently-played",
            "playlist-read-private",
            "playlist-read-collaborative"
        ].joined(separator: " ")
        
        let authURL = buildAuthURL(scopes: scopes)
        
        print("🎵 Opening Spotify auth URL...")
        
        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func handleCallback(url: URL) {
        print("🔄 Handling callback: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            errorMessage = "Invalid callback URL"
            return
        }
        
        if let code = queryItems.first(where: { $0.name == "code" })?.value {
            print("✅ Got authorization code")
            exchangeCodeForToken(code: code)
        } else if let error = queryItems.first(where: { $0.name == "error" })?.value {
            errorMessage = "Authentication failed: \(error)"
            print("❌ Auth error: \(error)")
        }
    }
    
    // MARK: - Token Management
    private func exchangeCodeForToken(code: String) {
        isLoading = true
        syncStatus = .syncing
        
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientId,
            "code_verifier": codeVerifier
        ]
        
        let bodyString = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleTokenError("Token exchange failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data, response in
                    self?.handleTokenResponse(data: data, response: response)
                }
            )
            .store(in: &cancellables)
    }
    
    private func refreshAccessToken(refreshToken: String) {
        print("🔄 Refreshing access token...")
        isLoading = true
        syncStatus = .syncing
        
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId
        ]
        
        let bodyString = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleTokenError("Token refresh failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data, response in
                    self?.handleTokenResponse(data: data, response: response, isRefresh: true)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleTokenResponse(data: Data, response: URLResponse, isRefresh: Bool = false) {
        do {
            let tokenResponse = try JSONDecoder().decode(EnhancedSpotifyTokenResponse.self, from: data)
            
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
            let scopes = tokenResponse.scope.components(separatedBy: " ")
            
            // Keep existing refresh token if not provided in refresh response
            var finalRefreshToken = tokenResponse.refresh_token
            if isRefresh && finalRefreshToken == nil {
                finalRefreshToken = dataStore.getTokenData()?.refreshToken
            }
            
            let tokenData = SpotifyTokenData(
                accessToken: tokenResponse.access_token,
                refreshToken: finalRefreshToken,
                expiresAt: expiresAt,
                scopes: scopes
            )
            
            dataStore.saveTokenData(tokenData)
            
            isAuthenticated = true
            syncStatus = .connected
            
            print("✅ Token saved, syncing fresh data...")
            syncAllData()
            
        } catch {
            handleTokenError("Failed to parse token response: \(error.localizedDescription)")
        }
    }
    
    private func handleTokenError(_ message: String) {
        isLoading = false
        syncStatus = .error(message)
        errorMessage = message
        isAuthenticated = false
        print("❌ Token error: \(message)")
    }
    
    // MARK: - Data Syncing
    func syncAllData() {
        guard isAuthenticated,
              let tokenData = dataStore.getTokenData(),
              !tokenData.isExpired else {
            syncStatus = .offline
            return
        }
        
        // Check if token needs refresh before syncing
        if tokenData.isExpiringSoon, let refreshToken = tokenData.refreshToken {
            refreshAccessToken(refreshToken: refreshToken)
            return
        }
        
        isLoading = true
        syncStatus = .syncing
        dataStore.isSyncing = true
        
        let group = DispatchGroup()
        var fetchErrors: [String] = []
        
        var newProfile: SpotifyUserProfile?
        var newTopArtists: [SpotifyArtist] = []
        var newTopTracks: [SpotifyTrack] = []
        var newPlaylists: [SpotifyPlaylist] = []
        var newRecentlyPlayed: [SpotifyPlayHistory] = []
        
        // Fetch all data in parallel
        group.enter()
        fetchUserProfile(token: tokenData.accessToken) { result in
            switch result {
            case .success(let profile):
                newProfile = profile
            case .failure(let error):
                fetchErrors.append("Profile: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        fetchTopArtists(token: tokenData.accessToken) { result in
            switch result {
            case .success(let artists):
                newTopArtists = artists
            case .failure(let error):
                fetchErrors.append("Artists: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        fetchTopTracks(token: tokenData.accessToken) { result in
            switch result {
            case .success(let tracks):
                newTopTracks = tracks
            case .failure(let error):
                fetchErrors.append("Tracks: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        fetchPlaylists(token: tokenData.accessToken) { result in
            switch result {
            case .success(let playlists):
                newPlaylists = playlists
            case .failure(let error):
                fetchErrors.append("Playlists: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        fetchRecentlyPlayed(token: tokenData.accessToken) { result in
            switch result {
            case .success(let recent):
                newRecentlyPlayed = recent
            case .failure(let error):
                fetchErrors.append("Recent: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.dataStore.isSyncing = false
            
            if fetchErrors.isEmpty {
                // Save all data to cache
                self?.dataStore.updateAllData(
                    profile: newProfile,
                    topArtists: newTopArtists,
                    topTracks: newTopTracks,
                    playlists: newPlaylists,
                    recentlyPlayed: newRecentlyPlayed
                )
                
                self?.syncStatus = .connected
                self?.errorMessage = nil
                print("✅ Successfully synced all Spotify data")
                
            } else {
                let errorMsg = "Some data failed to sync: \(fetchErrors.joined(separator: ", "))"
                self?.syncStatus = .error(errorMsg)
                self?.errorMessage = errorMsg
                print("⚠️ Partial sync completed with errors: \(fetchErrors)")
            }
        }
    }
    
    // MARK: - Individual API Calls
    private func fetchUserProfile(token: String, completion: @escaping (Result<SpotifyUserProfile, Error>) -> Void) {
        makeAPIRequest(endpoint: "me", token: token, type: SpotifyUserProfile.self, completion: completion)
    }
    
    private func fetchTopArtists(token: String, completion: @escaping (Result<[SpotifyArtist], Error>) -> Void) {
        makeAPIRequestWithDebug(
            endpoint: "me/top/artists?limit=50&time_range=medium_term",
            token: token,
            dataType: "artists"
        ) { result in
            switch result {
            case .success(let data):
                do {
                    // Try flexible model first
                    let flexibleResponse = try JSONDecoder().decode(FlexibleSpotifyTopItemsResponse<FlexibleSpotifyArtist>.self, from: data)
                    let convertedArtists = flexibleResponse.safeItems.compactMap { $0.toSpotifyArtist() }
                    print("✅ Successfully parsed \(convertedArtists.count) artists from \(flexibleResponse.safeItems.count) raw items")
                    completion(.success(convertedArtists))
                } catch {
                    print("❌ Artists JSON decode error (flexible model): \(error)")
                    
                    // Fallback to original model
                    do {
                        let response = try JSONDecoder().decode(SpotifyTopItemsResponse<SpotifyArtist>.self, from: data)
                        completion(.success(response.items))
                    } catch {
                        print("❌ Artists JSON decode error (original model): \(error)")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchTopTracks(token: String, completion: @escaping (Result<[SpotifyTrack], Error>) -> Void) {
        makeAPIRequestWithDebug(
            endpoint: "me/top/tracks?limit=50&time_range=medium_term",
            token: token,
            dataType: "tracks"
        ) { result in
            switch result {
            case .success(let data):
                do {
                    // Try flexible model first
                    let flexibleResponse = try JSONDecoder().decode(FlexibleSpotifyTopItemsResponse<FlexibleSpotifyTrack>.self, from: data)
                    let convertedTracks = flexibleResponse.safeItems.compactMap { $0.toSpotifyTrack() }
                    print("✅ Successfully parsed \(convertedTracks.count) tracks from \(flexibleResponse.safeItems.count) raw items")
                    completion(.success(convertedTracks))
                } catch {
                    print("❌ Tracks JSON decode error (flexible model): \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("🔍 Raw tracks response: \(jsonString.prefix(500))...")
                    }
                    
                    // Fallback to original model
                    do {
                        let response = try JSONDecoder().decode(SpotifyTopItemsResponse<SpotifyTrack>.self, from: data)
                        completion(.success(response.items))
                    } catch {
                        print("❌ Tracks JSON decode error (original model): \(error)")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchPlaylists(token: String, completion: @escaping (Result<[SpotifyPlaylist], Error>) -> Void) {
        makeAPIRequestWithDebug(
            endpoint: "me/playlists?limit=50",
            token: token,
            dataType: "playlists"
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(SpotifyPlaylistsResponse.self, from: data)
                    completion(.success(response.items))
                } catch {
                    print("❌ Playlists JSON decode error: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchRecentlyPlayed(token: String, completion: @escaping (Result<[SpotifyPlayHistory], Error>) -> Void) {
        makeAPIRequestWithDebug(
            endpoint: "me/player/recently-played?limit=50",
            token: token,
            dataType: "recent"
        ) { result in
            switch result {
            case .success(let data):
                do {
                    // Try flexible model first
                    let flexibleResponse = try JSONDecoder().decode(FlexibleSpotifyRecentlyPlayedResponse.self, from: data)
                    let convertedHistory = flexibleResponse.safeItems.compactMap { $0.toSpotifyPlayHistory() }
                    print("✅ Successfully parsed \(convertedHistory.count) recent tracks from \(flexibleResponse.safeItems.count) raw items")
                    completion(.success(convertedHistory))
                } catch {
                    print("❌ Recent JSON decode error (flexible model): \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("🔍 Raw recent response: \(jsonString.prefix(500))...")
                    }
                    
                    // Fallback to original model
                    do {
                        let response = try JSONDecoder().decode(SpotifyRecentlyPlayedResponse.self, from: data)
                        completion(.success(response.items))
                    } catch {
                        print("❌ Recent JSON decode error (original model): \(error)")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func makeAPIRequest<T: Codable>(
        endpoint: String,
        token: String,
        type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.spotify.com/v1/\(endpoint)") else {
            completion(.failure(NSError(domain: "UnifiedSpotifyManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: type, decoder: JSONDecoder())
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { data in
                    completion(.success(data))
                }
            )
            .store(in: &cancellables)
    }
    
    private func makeAPIRequestWithDebug(
        endpoint: String,
        token: String,
        dataType: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.spotify.com/v1/\(endpoint)") else {
            completion(.failure(NSError(domain: "UnifiedSpotifyManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔍 Fetching \(dataType) from: \(url)")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        print("❌ \(dataType) API request failed: \(error)")
                        completion(.failure(error))
                    }
                },
                receiveValue: { data, response in
                    if let httpResponse = response as? HTTPURLResponse {
                        print("✅ \(dataType) HTTP Status: \(httpResponse.statusCode)")
                    }
                    
                    print("✅ \(dataType) data size: \(data.count) bytes")
                    completion(.success(data))
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Auto Sync Timer
    private func startAutoSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            self?.checkForAutoSync()
        }
    }
    
    private func checkForAutoSync() {
        // Only auto-sync if authenticated and cache is getting stale
        guard isAuthenticated, dataStore.isCacheExpired else { return }
        
        print("🔄 Auto-syncing stale cache...")
        syncAllData()
    }
    
    // MARK: - Public Methods
    func forceSync() {
        guard isAuthenticated else {
            errorMessage = "Not authenticated"
            return
        }
        syncAllData()
    }
    
    func logout() {
        dataStore.clearTokenData()
        isAuthenticated = false
        syncStatus = .offline
        errorMessage = nil
        syncTimer?.invalidate()
        syncTimer = nil
        print("👋 Logged out of Spotify")
    }
    
    func clearAllData() {
        logout()
        dataStore.clearCachedData()
        
        userProfile = nil
        topArtists = []
        topTracks = []
        playlists = []
        recentlyPlayed = []
        print("🗑️ Cleared all Spotify data")
    }
    
    // MARK: - Helper Methods
    private func generateCodeVerifier() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = Data(SHA256.hash(data: data))
        return hash.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    private func buildAuthURL(scopes: String) -> String {
        let baseURL = "https://accounts.spotify.com/authorize"
        let params = [
            "client_id": clientId,
            "response_type": "code",
            "redirect_uri": redirectURI,
            "scope": scopes,
            "show_dialog": "true",
            "code_challenge_method": "S256",
            "code_challenge": codeChallenge
        ]
        
        let queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        var components = URLComponents(string: baseURL)!
        components.queryItems = queryItems
        
        return components.url!.absoluteString
    }
}

// MARK: - Convenience Properties
extension UnifiedSpotifyManager {
    var cacheStatusText: String {
        dataStore.cacheStatusText
    }
    
    var hasOfflineData: Bool {
        dataStore.isDataAvailable
    }
    
    var isOfflineMode: Bool {
        !isAuthenticated && hasOfflineData
    }
}