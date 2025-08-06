//
//  EnhancedSpotifyManager.swift
//  FrequencyFinder
//
//  Enhanced Spotify integration with top artists, tracks, playlists
//

import SwiftUI
import Combine
import CryptoKit
import Foundation

// MARK: - Enhanced Spotify Models

struct SpotifyTopItemsResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let limit: Int
    let offset: Int
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

struct SpotifyPlaylistsResponse: Codable {
    let items: [SpotifyPlaylist]
    let total: Int
    let limit: Int
    let offset: Int
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
    
    // Custom coding keys to handle the "public" keyword issue
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

struct SpotifyExternalUrls: Codable {
    let spotify: String?
}

struct SpotifyRecentlyPlayedResponse: Codable {
    let items: [SpotifyPlayHistory]
    let cursors: SpotifyCursors?
}

struct SpotifyPlayHistory: Codable, Identifiable {
    let track: SpotifyTrack
    let played_at: String
    let context: SpotifyContext?
    
    var id: String { track.id + played_at }
}

struct SpotifyCursors: Codable {
    let after: String?
    let before: String?
}

struct SpotifyContext: Codable {
    let type: String
    let href: String?
    let external_urls: SpotifyExternalUrls?
}

// MARK: - Enhanced Token Models (with unique names to avoid conflicts)

struct EnhancedSpotifyTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
}

struct EnhancedSpotifyErrorResponse: Codable {
    let error: String
    let error_description: String?
}

// MARK: - Enhanced Spotify Manager

class EnhancedSpotifyManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: SpotifyUserProfile?
    @Published var topArtists: [SpotifyArtist] = []
    @Published var topTracks: [SpotifyTrack] = []
    @Published var playlists: [SpotifyPlaylist] = []
    @Published var recentlyPlayed: [SpotifyPlayHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let clientId = "7c5840c8370940a6be5a12336241f464"
    private let redirectURI = "frequencyfinder://callback"
    private let tokenKey = "enhanced_spotify_access_token" // Different key to avoid conflicts
    
    // PKCE parameters
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkStoredToken()
    }
    
    // MARK: - PKCE Helper Methods
    private func generateCodeVerifier() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = data.enhancedSha256()
        return hash.enhancedBase64URLEncodedString()
    }
    
    // MARK: - Authentication
    func authenticate() {
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        // Request more scopes for additional data
        let scopes = [
            "user-read-private",
            "user-read-email",
            "user-top-read",
            "user-read-recently-played",
            "playlist-read-private",
            "playlist-read-collaborative"
        ].joined(separator: " ")
        
        let authURL = buildAuthURL(scopes: scopes)
        
        print("🎵 Opening Enhanced Spotify auth URL: \(authURL)")
        
        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        }
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
    
    // MARK: - Handle Callback
    func handleCallback(url: URL) {
        print("🔄 Handling Enhanced Spotify callback: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            errorMessage = "Invalid callback URL"
            return
        }
        
        if let code = queryItems.first(where: { $0.name == "code" })?.value {
            print("✅ Got Enhanced Spotify authorization code: \(code.prefix(20))...")
            exchangeCodeForToken(code: code)
        } else if let error = queryItems.first(where: { $0.name == "error" })?.value {
            errorMessage = "Authentication failed: \(error)"
            print("❌ Enhanced Spotify auth error: \(error)")
        }
    }
    
    private func exchangeCodeForToken(code: String) {
        isLoading = true
        
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
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Token exchange failed: \(error.localizedDescription)"
                        print("❌ Enhanced Spotify token exchange error: \(error)")
                    }
                },
                receiveValue: { [weak self] data, response in
                    do {
                        let tokenResponse = try JSONDecoder().decode(EnhancedSpotifyTokenResponse.self, from: data)
                        print("✅ Got Enhanced Spotify access token with scopes")
                        self?.saveToken(tokenResponse.access_token)
                        self?.fetchAllData()
                    } catch {
                        self?.errorMessage = "Failed to parse token response: \(error.localizedDescription)"
                        print("❌ Enhanced Spotify JSON decode error: \(error)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Token Management
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        isAuthenticated = true
    }
    
    private func checkStoredToken() {
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            isAuthenticated = true
            fetchAllData()
        }
    }
    
    private var accessToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // MARK: - Fetch All Data
    func fetchAllData() {
        fetchUserProfile()
        fetchTopArtists()
        fetchTopTracks()
        fetchPlaylists()
        fetchRecentlyPlayed()
    }
    
    // MARK: - API Calls
    func fetchUserProfile() {
        makeRequest(endpoint: "me", type: SpotifyUserProfile.self) { [weak self] result in
            switch result {
            case .success(let profile):
                self?.userProfile = profile
                print("✅ Got Enhanced Spotify user profile: \(profile.display_name ?? profile.id)")
            case .failure(let error):
                print("❌ Enhanced Spotify profile fetch error: \(error)")
            }
        }
    }
    
    func fetchTopArtists(timeRange: String = "medium_term") {
        makeRequest(
            endpoint: "me/top/artists?limit=20&time_range=\(timeRange)",
            type: SpotifyTopItemsResponse<SpotifyArtist>.self
        ) { [weak self] result in
            switch result {
            case .success(let response):
                self?.topArtists = response.items
                print("✅ Got \(response.items.count) top artists")
            case .failure(let error):
                print("❌ Top artists fetch error: \(error)")
            }
        }
    }
    
    func fetchTopTracks(timeRange: String = "medium_term") {
        makeRequest(
            endpoint: "me/top/tracks?limit=20&time_range=\(timeRange)",
            type: SpotifyTopItemsResponse<SpotifyTrack>.self
        ) { [weak self] result in
            switch result {
            case .success(let response):
                self?.topTracks = response.items
                print("✅ Got \(response.items.count) top tracks")
            case .failure(let error):
                print("❌ Top tracks fetch error: \(error)")
            }
        }
    }
    
    func fetchPlaylists() {
        makeRequest(
            endpoint: "me/playlists?limit=50",
            type: SpotifyPlaylistsResponse.self
        ) { [weak self] result in
            switch result {
            case .success(let response):
                self?.playlists = response.items
                print("✅ Got \(response.items.count) playlists")
            case .failure(let error):
                print("❌ Playlists fetch error: \(error)")
            }
        }
    }
    
    func fetchRecentlyPlayed() {
        makeRequest(
            endpoint: "me/player/recently-played?limit=20",
            type: SpotifyRecentlyPlayedResponse.self
        ) { [weak self] result in
            switch result {
            case .success(let response):
                self?.recentlyPlayed = response.items
                print("✅ Got \(response.items.count) recently played tracks")
            case .failure(let error):
                print("❌ Recently played fetch error: \(error)")
            }
        }
    }
    
    // MARK: - Generic API Request Helper
    private func makeRequest<T: Codable>(
        endpoint: String,
        type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let token = accessToken else {
            completion(.failure(NSError(domain: "EnhancedSpotifyManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No access token"])))
            return
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/\(endpoint)") else {
            completion(.failure(NSError(domain: "EnhancedSpotifyManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: type, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
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
    
    // MARK: - Logout
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        isAuthenticated = false
        userProfile = nil
        topArtists = []
        topTracks = []
        playlists = []
        recentlyPlayed = []
        errorMessage = nil
    }
}

// MARK: - Enhanced Views

struct EnhancedSpotifyView: View {
    @StateObject private var spotifyManager = EnhancedSpotifyManager()
    
    var body: some View {
        NavigationView {
            VStack {
                if spotifyManager.isLoading {
                    ProgressView("Loading Spotify data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !spotifyManager.isAuthenticated {
                    // Authentication View
                    VStack(spacing: 20) {
                        Text("🎵 Connect to Spotify")
                            .font(.title2)
                            .bold()
                        
                        Text("Get insights into your music taste with top artists, tracks, playlists, and listening history!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Connect to Spotify") {
                            spotifyManager.authenticate()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        if let error = spotifyManager.errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                } else {
                    // Authenticated - Show Tabbed Data
                    SpotifyDataTabView(manager: spotifyManager)
                }
            }
            .navigationTitle("Spotify Data")
            .onOpenURL { url in
                if url.scheme == "frequencyfinder" {
                    spotifyManager.handleCallback(url: url)
                }
            }
        }
    }
}

struct SpotifyDataTabView: View {
    @ObservedObject var manager: EnhancedSpotifyManager
    
    var body: some View {
        TabView {
            // Profile Tab
            ProfileTabView(manager: manager)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            
            // Top Artists Tab
            TopArtistsTabView(manager: manager)
                .tabItem {
                    Label("Artists", systemImage: "music.mic")
                }
            
            // Top Tracks Tab
            TopTracksTabView(manager: manager)
                .tabItem {
                    Label("Tracks", systemImage: "music.note")
                }
            
            // Playlists Tab
            PlaylistsTabView(manager: manager)
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }
            
            // Recent Tab
            RecentTabView(manager: manager)
                .tabItem {
                    Label("Recent", systemImage: "clock")
                }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Disconnect") {
                    manager.logout()
                }
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Individual Tab Views

struct ProfileTabView: View {
    @ObservedObject var manager: EnhancedSpotifyManager
    
    var body: some View {
        ScrollView {
            if let profile = manager.userProfile {
                VStack(spacing: 20) {
                    // Profile Header
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
                        
                        VStack(alignment: .leading) {
                            Text(profile.display_name ?? "Spotify User")
                                .font(.title2)
                                .bold()
                            
                            if let email = profile.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Stats Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Followers", value: "\(profile.followers?.total ?? 0)")
                        StatCard(title: "Country", value: profile.country ?? "Unknown")
                        StatCard(title: "Plan", value: profile.product?.capitalized ?? "Free")
                        StatCard(title: "Playlists", value: "\(manager.playlists.count)")
                    }
                }
                .padding()
            }
        }
    }
}

struct StatCard: View {
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

struct TopArtistsTabView: View {
    @ObservedObject var manager: EnhancedSpotifyManager
    
    var body: some View {
        List(manager.topArtists) { artist in
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
                
                VStack(alignment: .leading) {
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
        }
        .navigationTitle("Top Artists")
    }
}

struct TopTracksTabView: View {
    @ObservedObject var manager: EnhancedSpotifyManager
    
    var body: some View {
        List(manager.topTracks) { track in
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
                
                VStack(alignment: .leading) {
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
            }
        }
        .navigationTitle("Top Tracks")
    }
    
    private func formatDuration(_ ms: Int) -> String {
        let seconds = ms / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct PlaylistsTabView: View {
    @ObservedObject var manager: EnhancedSpotifyManager
    
    var body: some View {
        List(manager.playlists) { playlist in
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
                
                VStack(alignment: .leading) {
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
        }
        .navigationTitle("Playlists")
    }
}

struct RecentTabView: View {
    @ObservedObject var manager: EnhancedSpotifyManager
    
    var body: some View {
        List(manager.recentlyPlayed) { item in
            HStack {
                AsyncImage(url: URL(string: item.track.album.images?.first?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading) {
                    Text(item.track.name)
                        .font(.headline)
                    Text(item.track.artists.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatPlayedAt(item.played_at))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Recently Played")
    }
    
    private func formatPlayedAt(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Unknown" }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Enhanced Crypto Extensions (with unique names to avoid conflicts)

extension Data {
    func enhancedSha256() -> Data {
        return Data(SHA256.hash(data: self))
    }
    
    func enhancedBase64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
