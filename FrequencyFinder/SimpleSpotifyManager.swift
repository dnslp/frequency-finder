//
// MARK: - Simple Spotify Integration - Just for User Profile
// No App Remote needed, just Web API authentication
//

import SwiftUI
import AuthenticationServices
import Combine

// MARK: - Simple Spotify Manager (Web API Only)
class SimpleSpotifyManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: SpotifyUserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let clientId = "7c5840c8370940a6be5a12336241f464"
    private let redirectURI = "frequencyfinder://callback"
    private let tokenKey = "spotify_access_token"
    
    // PKCE parameters
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check if we have a stored token
        checkStoredToken()
    }
    
    // MARK: - PKCE Helper Methods
    private func generateCodeVerifier() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = data.sha256()
        return hash.base64URLEncodedString()
    }
    
    // MARK: - Authentication
    func authenticate() {
        // Generate PKCE parameters
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        let scopes = "user-read-private user-read-email"
        let authURL = buildAuthURL(scopes: scopes)
        
        print("🎵 Opening Spotify auth URL (PKCE): \(authURL)")
        
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
        print("🔄 Handling callback: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            errorMessage = "Invalid callback URL"
            return
        }
        
        // Check for authorization code
        if let code = queryItems.first(where: { $0.name == "code" })?.value {
            print("✅ Got authorization code: \(code.prefix(20))...")
            exchangeCodeForToken(code: code)
        } else if let error = queryItems.first(where: { $0.name == "error" })?.value {
            errorMessage = "Authentication failed: \(error)"
            print("❌ Auth error: \(error)")
        }
    }
    
    private func exchangeCodeForToken(code: String) {
        isLoading = true
        
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Use PKCE flow instead of client_secret
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientId,
            "code_verifier": codeVerifier  // PKCE parameter instead of client_secret
        ]
        
        let bodyString = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🔄 Exchanging code for token with PKCE...")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Token exchange failed: \(error.localizedDescription)"
                        print("❌ Token exchange error: \(error)")
                    }
                },
                receiveValue: { [weak self] data, response in
                    // Debug: Print raw response
                    if let httpResponse = response as? HTTPURLResponse {
                        print("🔍 HTTP Status: \(httpResponse.statusCode)")
                    }
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🔍 Raw response: \(responseString)")
                    }
                    
                    do {
                        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
                        print("✅ Got access token: \(tokenResponse.access_token.prefix(20))...")
                        self?.saveToken(tokenResponse.access_token)
                        self?.fetchUserProfile()
                    } catch {
                        self?.errorMessage = "Failed to parse token response: \(error.localizedDescription)"
                        print("❌ JSON decode error: \(error)")
                        
                        // Try to parse as error response
                        if let errorResponse = try? JSONDecoder().decode(SpotifyErrorResponse.self, from: data) {
                            print("❌ Spotify API error: \(errorResponse.error) - \(errorResponse.error_description ?? "Unknown")")
                            self?.errorMessage = "Spotify error: \(errorResponse.error_description ?? errorResponse.error)"
                        }
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
            fetchUserProfile()
        }
    }
    
    private var accessToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // MARK: - Fetch User Profile
    func fetchUserProfile() {
        guard let token = accessToken else {
            errorMessage = "No access token"
            return
        }
        
        isLoading = true
        
        let profileURL = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: profileURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SpotifyUserProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                        print("❌ Profile fetch error: \(error)")
                    }
                },
                receiveValue: { [weak self] profile in
                    print("✅ Got user profile: \(profile.display_name ?? profile.id)")
                    self?.userProfile = profile
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Logout
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        isAuthenticated = false
        userProfile = nil
        errorMessage = nil
    }
}

// MARK: - Token Response Model
struct SpotifyTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
}

// MARK: - Error Response Model
struct SpotifyErrorResponse: Codable {
    let error: String
    let error_description: String?
}

// MARK: - Crypto Extensions for PKCE
import CryptoKit

extension Data {
    func sha256() -> Data {
        return Data(SHA256.hash(data: self))
    }
    
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}

// MARK: - Simple Spotify View
struct SimpleSpotifyView: View {
    @StateObject private var spotifyManager = SimpleSpotifyManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎵 Spotify Integration")
                .font(.title2)
                .bold()
            
            if spotifyManager.isLoading {
                ProgressView("Loading...")
            } else if !spotifyManager.isAuthenticated {
                // Not authenticated
                VStack(spacing: 16) {
                    Text("Connect your Spotify account to see your profile")
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
            } else {
                // Authenticated - show profile
                if let profile = spotifyManager.userProfile {
                    ProfileCard(profile: profile)
                } else {
                    Text("Fetching profile...")
                        .foregroundColor(.secondary)
                }
                
                Button("Disconnect") {
                    spotifyManager.logout()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .onOpenURL { url in
            // Handle the callback URL
            if url.scheme == "frequencyfinder" {
                spotifyManager.handleCallback(url: url)
            }
        }
    }
}

// MARK: - Profile Card View
struct ProfileCard: View {
    let profile: SpotifyUserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(profile.display_name ?? "Spotify User")
                        .font(.headline)
                    
                    if let email = profile.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Profile image if available
                if let images = profile.images, let firstImage = images.first {
                    AsyncImage(url: URL(string: firstImage.url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                }
            }
            
            Divider()
            
            // Additional info
            VStack(alignment: .leading, spacing: 8) {
                if let country = profile.country {
                    Label(country, systemImage: "globe")
                        .font(.caption)
                }
                
                if let followers = profile.followers {
                    Label("\(followers.total) followers", systemImage: "person.2")
                        .font(.caption)
                }
                
                if let product = profile.product {
                    Label(product.capitalized, systemImage: "star")
                        .font(.caption)
                        .foregroundColor(product == "premium" ? .green : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

//
// MARK: - Updated ProfileView Integration
//

// Replace your existing Spotify section in ProfileView with this:

/*
Section(header: Text("🎵 Spotify Profile")) {
    SimpleSpotifyView()
}
*/

// MARK: - Required Info.plist (Same as before)
/*
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>DNSLP.FrequencyFinder.spotify</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>frequencyfinder</string>
        </array>
    </dict>
</array>
*/
