//  Enhanced SpotifyManager.swift
//  FrequencyFinder
//

import Foundation
import Combine

class SpotifyManager: ObservableObject {
    @Published var profile: SpotifyUserProfile?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isConnected = false
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Fetch user profile using access token
    func fetchUserProfile(accessToken: String) {
        guard !accessToken.isEmpty else {
            errorMessage = "No access token available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://api.spotify.com/v1/me") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SpotifyUserProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                    print("❌ Spotify API Error: \(error)")
                }
            } receiveValue: { [weak self] profile in
                self?.profile = profile
                self?.isConnected = true
                print("✅ Successfully fetched Spotify profile for: \(profile.display_name ?? profile.id)")
            }
            .store(in: &cancellables)
    }
    
    /// Clear all data (for logout)
    func clearData() {
        profile = nil
        errorMessage = nil
        isLoading = false
        isConnected = false
    }
    
    /// Check if we have a valid connection
    func checkConnection(with accessToken: String?) -> Bool {
        guard let token = accessToken, !token.isEmpty else {
            isConnected = false
            return false
        }
        return isConnected
    }
}
