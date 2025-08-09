//
//  SpotifyAuth.swift
//  FrequencyFinder
//
//  Spotify authentication service with PKCE support
//

import Foundation
import CryptoKit
import UIKit

class SpotifyAuth: ObservableObject {
    @Published var isAuthenticated = false
    @Published var tokenData: SpotifyTokenData?
    @Published var errorMessage: String?
    
    private let clientId = "7c5840c8370940a6be5a12336241f464"
    private let redirectURI = "frequencyfinder://callback"
    private let tokenKey = "spotify_token_data"
    
    // PKCE parameters
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    
    init() {
        loadStoredToken()
    }
    
    // MARK: - Token Management
    
    private func loadStoredToken() {
        guard let data = UserDefaults.standard.data(forKey: tokenKey),
              let stored = try? JSONDecoder().decode(SpotifyTokenData.self, from: data) else {
            return
        }
        
        // Check if token is still valid
        if stored.expiresAt > Date() {
            tokenData = stored
            isAuthenticated = true
        } else if let refreshToken = stored.refreshToken {
            // Try to refresh the token
            refreshAccessToken(refreshToken: refreshToken)
        }
    }
    
    private func saveToken(_ data: SpotifyTokenData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: tokenKey)
        tokenData = data
        isAuthenticated = true
    }
    
    private func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        tokenData = nil
        isAuthenticated = false
    }
    
    // MARK: - PKCE Helper Methods
    
    private func generateCodeVerifier() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = Data(SHA256.hash(data: data))
        return hash.base64URLEncodedString()
    }
    
    // MARK: - Authentication Flow
    
    func authenticate(scopes: [String]) {
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        let authURL = buildAuthURL(scopes: scopes.joined(separator: " "))
        
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
    
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            errorMessage = "Invalid callback URL"
            return
        }
        
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            errorMessage = error
            return
        }
        
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            errorMessage = "No authorization code received"
            return
        }
        
        exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) {
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
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                self?.handleTokenResponse(data: data)
            }
        }.resume()
    }
    
    private func refreshAccessToken(refreshToken: String) {
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
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.clearToken()
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    self?.clearToken()
                    return
                }
                
                self?.handleTokenResponse(data: data, existingRefreshToken: refreshToken)
            }
        }.resume()
    }
    
    private func handleTokenResponse(data: Data, existingRefreshToken: String? = nil) {
        do {
            let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
            
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
            let scopes = tokenResponse.scope.components(separatedBy: " ")
            
            // Use new refresh token if provided, otherwise keep existing one
            var finalRefreshToken = tokenResponse.refresh_token
            if finalRefreshToken == nil && existingRefreshToken != nil {
                finalRefreshToken = existingRefreshToken
            }
            
            let tokenData = SpotifyTokenData(
                accessToken: tokenResponse.access_token,
                refreshToken: finalRefreshToken,
                expiresAt: expiresAt,
                scopes: scopes
            )
            
            saveToken(tokenData)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to parse token response: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Public Methods
    
    func logout() {
        clearToken()
    }
    
    func getCurrentToken() -> String? {
        // Check if token needs refresh
        if let tokenData = tokenData {
            if tokenData.expiresAt > Date().addingTimeInterval(300) { // 5 minute buffer
                return tokenData.accessToken
            } else if let refreshToken = tokenData.refreshToken {
                refreshAccessToken(refreshToken: refreshToken)
            }
        }
        return tokenData?.accessToken
    }
}

// MARK: - Data Extension

private extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}