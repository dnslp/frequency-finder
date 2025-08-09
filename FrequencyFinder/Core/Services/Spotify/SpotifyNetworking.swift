//
//  SpotifyNetworking.swift
//  FrequencyFinder
//
//  Spotify API networking service
//

import Foundation
import Combine

class SpotifyNetworking: ObservableObject {
    private let auth: SpotifyAuth
    private var cancellables = Set<AnyCancellable>()
    
    init(auth: SpotifyAuth) {
        self.auth = auth
    }
    
    // MARK: - Generic API Request Method
    
    private func makeAPIRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let token = auth.getCurrentToken() else {
            print("❌ No auth token available for \(endpoint)")
            completion(.failure(SpotifyError.notAuthenticated))
            return
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/\(endpoint)") else {
            print("❌ Invalid URL for endpoint: \(endpoint)")
            completion(.failure(SpotifyError.invalidURL))
            return
        }
        
        print("🌐 Making API request to: \(url)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(SpotifyError.noData))
                    return
                }
                
                // Handle HTTP errors
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    let errorMsg = "HTTP \(httpResponse.statusCode)"
                    print("❌ HTTP Error \(httpResponse.statusCode) for \(url)")
                    completion(.failure(SpotifyError.httpError(errorMsg)))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(responseType, from: data)
                    completion(.success(result))
                } catch {
                    print("❌ Failed to decode \(responseType): \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - API Methods
    
    func fetchUserProfile(completion: @escaping (Result<SpotifyUserProfile, Error>) -> Void) {
        makeAPIRequest(endpoint: "me", responseType: SpotifyUserProfile.self, completion: completion)
    }
    
    func fetchTopArtists(timeRange: String = "medium_term", completion: @escaping (Result<[SpotifyArtist], Error>) -> Void) {
        // Try flexible parsing first, then fallback to strict parsing
        makeAPIRequest(
            endpoint: "me/top/artists?time_range=\(timeRange)&limit=50",
            responseType: FlexibleSpotifyTopItemsResponse<FlexibleSpotifyArtist>.self
        ) { result in
            switch result {
            case .success(let flexibleResponse):
                let convertedArtists = flexibleResponse.safeItems.compactMap { $0.toSpotifyArtist() }
                completion(.success(convertedArtists))
            case .failure(_):
                // Fallback to strict parsing
                self.makeAPIRequest(
                    endpoint: "me/top/artists?time_range=\(timeRange)&limit=50",
                    responseType: SpotifyTopItemsResponse<SpotifyArtist>.self
                ) { strictResult in
                    switch strictResult {
                    case .success(let response):
                        completion(.success(response.items))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func fetchTopTracks(timeRange: String = "medium_term", completion: @escaping (Result<[SpotifyTrack], Error>) -> Void) {
        // Try flexible parsing first, then fallback to strict parsing
        makeAPIRequest(
            endpoint: "me/top/tracks?time_range=\(timeRange)&limit=50",
            responseType: FlexibleSpotifyTopItemsResponse<FlexibleSpotifyTrack>.self
        ) { result in
            switch result {
            case .success(let flexibleResponse):
                let convertedTracks = flexibleResponse.safeItems.compactMap { $0.toSpotifyTrack() }
                completion(.success(convertedTracks))
            case .failure(_):
                // Fallback to strict parsing
                self.makeAPIRequest(
                    endpoint: "me/top/tracks?time_range=\(timeRange)&limit=50",
                    responseType: SpotifyTopItemsResponse<SpotifyTrack>.self
                ) { strictResult in
                    switch strictResult {
                    case .success(let response):
                        completion(.success(response.items))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func fetchPlaylists(completion: @escaping (Result<[SpotifyPlaylist], Error>) -> Void) {
        makeAPIRequest(
            endpoint: "me/playlists?limit=50",
            responseType: SpotifyPlaylistsResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchRecentlyPlayed(completion: @escaping (Result<[SpotifyPlayHistory], Error>) -> Void) {
        // Try flexible parsing first, then fallback to strict parsing
        makeAPIRequest(
            endpoint: "me/player/recently-played?limit=50",
            responseType: FlexibleSpotifyRecentlyPlayedResponse.self
        ) { result in
            switch result {
            case .success(let flexibleResponse):
                let convertedHistory = flexibleResponse.safeItems.compactMap { $0.toSpotifyPlayHistory() }
                completion(.success(convertedHistory))
            case .failure(_):
                // Fallback to strict parsing
                self.makeAPIRequest(
                    endpoint: "me/player/recently-played?limit=50",
                    responseType: SpotifyRecentlyPlayedResponse.self
                ) { strictResult in
                    switch strictResult {
                    case .success(let response):
                        completion(.success(response.items))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}

// MARK: - Spotify Error Types

enum SpotifyError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case noData
    case httpError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Spotify"
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .httpError(let message):
            return "HTTP Error: \(message)"
        }
    }
}