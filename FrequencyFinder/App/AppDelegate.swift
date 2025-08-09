//
// MARK: - Corrected AppDelegate.swift based on Official Spotify iOS SDK
//

import UIKit
import SpotifyiOS

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Spotify Objects
    var appRemote: SPTAppRemote!
    var sessionManager: SPTSessionManager!

    let clientID = "7c5840c8370940a6be5a12336241f464"
    let redirectURI = URL(string: "frequencyfinder://callback")!
    private let tokenKey = "spotifyAccessToken"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Spotify
        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURI)

        // Setup Session Manager for PKCE
        sessionManager = SPTSessionManager(configuration: configuration, delegate: self)

        // Setup App Remote for playback/control
        appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self

        // Try to connect if we have a stored token
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            print("🔄 Found saved token, attempting connection...")
            appRemote.connectionParameters.accessToken = token
            appRemote.connect()
        }

        return true
    }

    /// Call this from your UI to start the Spotify OAuth flow
    func startSpotifyLogin() {
        print("🎵 Starting Spotify login flow...")
        print("🔍 Client ID: \(clientID)")
        print("🔍 Redirect URI: \(redirectURI)")
        print("🔍 Session Manager exists: \(sessionManager != nil)")
        
        guard sessionManager != nil else {
            print("❌ Session manager is nil!")
            return
        }
        
        let scopes: SPTScope = [.appRemoteControl, .userReadPrivate, .userReadEmail]
        print("🔍 Initiating session with scopes: \(scopes)")
        
        sessionManager.initiateSession(with: scopes, options: .default, campaign: nil)
        print("✅ Session initiation called successfully")
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("📱 Received URL: \(url)")
        print("📱 URL Scheme: \(url.scheme ?? "none")")
        print("📱 URL Host: \(url.host ?? "none")")
        print("📱 URL Path: \(url.path)")
        print("📱 URL Query: \(url.query ?? "none")")
        
        // Check if this is our Spotify callback
        if url.scheme == "frequencyfinder" {
            print("✅ Correct URL scheme detected")
            let result = sessionManager.application(app, open: url, options: options)
            print("🔍 Session manager handled URL: \(result)")
            return result
        } else {
            print("⚠️ URL scheme doesn't match expected 'frequencyfinder'")
            return false
        }
    }

    /// Disconnect from Spotify and clear tokens
    func disconnectSpotify() {
        print("🔌 Disconnecting from Spotify...")
        appRemote.disconnect()
        UserDefaults.standard.removeObject(forKey: tokenKey)
        appRemote.connectionParameters.accessToken = nil
    }
}

// MARK: - SPTSessionManagerDelegate (Corrected based on real SDK)
extension AppDelegate: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ SUCCESS: Spotify authentication successful!")
        print("🔑 Access Token: \(session.accessToken.prefix(20))...")
        print("🔑 Expires At: \(session.expirationDate)")
        print("🔑 Scope: \(session.scope)")
        
        // Save the access token
        UserDefaults.standard.set(session.accessToken, forKey: tokenKey)
        
        // Set the token for App Remote and connect
        appRemote.connectionParameters.accessToken = session.accessToken
        print("🔌 Attempting to connect App Remote with new token...")
        appRemote.connect()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .spotifyDidConnect, object: session)
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ FAILURE: Spotify authentication failed!")
        print("❌ Error: \(error)")
        print("❌ Error Details: \(error.localizedDescription)")
        
        // Additional error logging
        let nsError = error as NSError
        print("❌ Error Domain: \(nsError.domain)")
        print("❌ Error Code: \(nsError.code)")
        print("❌ User Info: \(nsError.userInfo)")
        
        NotificationCenter.default.post(name: .spotifyDidFail, object: error)
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("🔄 Spotify token renewed successfully")
        UserDefaults.standard.set(session.accessToken, forKey: tokenKey)
        appRemote.connectionParameters.accessToken = session.accessToken
        NotificationCenter.default.post(name: .spotifyDidConnect, object: session)
    }
}

// MARK: - SPTAppRemoteDelegate (Corrected based on real SDK)
extension AppDelegate: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("🎵 SUCCESS: Spotify App Remote connected!")
        
        // Subscribe to player state updates
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error = error {
                print("⚠️ Player state subscription error: \(error)")
            } else {
                print("✅ Successfully subscribed to player state updates")
            }
        })
        
        NotificationCenter.default.post(name: .spotifyRemoteDidConnect, object: nil)
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("⚠️ AppRemote disconnected")
        if let error = error {
            print("⚠️ Disconnect reason: \(error.localizedDescription)")
        }
        NotificationCenter.default.post(name: .spotifyRemoteDidDisconnect, object: error)
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("❌ FAILURE: AppRemote failed to connect!")
        if let error = error {
            print("❌ Connection Error: \(error)")
            print("❌ Error Details: \(error.localizedDescription)")
            
            let nsError = error as NSError
            print("❌ Error Domain: \(nsError.domain)")
            print("❌ Error Code: \(nsError.code)")
            
            // Try to provide helpful error messages based on common error codes
            switch nsError.code {
            case 1:
                print("❌ LIKELY ISSUE: Spotify app is not installed")
            case 2:
                print("❌ LIKELY ISSUE: User is not logged into Spotify app")
            case 3:
                print("❌ LIKELY ISSUE: No active Spotify device found")
            default:
                print("❌ Error code \(nsError.code): \(error.localizedDescription)")
            }
        } else {
            print("❌ Connection failed with unknown error")
        }
        
        NotificationCenter.default.post(name: .spotifyRemoteDidFail, object: error)
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate
extension AppDelegate: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("▶️ Player state changed")
        print("▶️ Track: \(playerState.track.name)")
        print("▶️ Artist: \(playerState.track.artist.name)")
        print("▶️ Is Paused: \(playerState.isPaused)")
        print("▶️ Playback Position: \(playerState.playbackPosition)")
        
        NotificationCenter.default.post(name: .spotifyPlayerStateChanged, object: playerState)
    }
}

// MARK: - Debug Helper Methods
extension AppDelegate {
    /// Call this to check current Spotify state
    func debugSpotifyState() {
        print("🔍 === SPOTIFY DEBUG STATE ===")
        print("🔍 Client ID: \(clientID)")
        print("🔍 Redirect URI: \(redirectURI)")
        print("🔍 Session Manager exists: \(sessionManager != nil)")
        print("🔍 App Remote exists: \(appRemote != nil)")
        print("🔍 Stored token: \(UserDefaults.standard.string(forKey: tokenKey)?.prefix(20) ?? "none")...")
        print("🔍 App Remote connected: \(appRemote?.isConnected ?? false)")
        print("🔍 Current access token: \(appRemote?.connectionParameters.accessToken?.prefix(20) ?? "none")...")
        
        // Check if Spotify app is available
        if let spotifyURL = URL(string: "spotify://") {
            let canOpen = UIApplication.shared.canOpenURL(spotifyURL)
            print("🔍 Can open Spotify app: \(canOpen)")
        }
        
        print("🔍 === END DEBUG STATE ===")
    }
    
    /// Force a fresh login (clears everything)
    func forceSpotifyReauth() {
        print("🔄 Forcing fresh Spotify authentication...")
        
        // Disconnect and clear everything
        appRemote?.disconnect()
        UserDefaults.standard.removeObject(forKey: tokenKey)
        appRemote.connectionParameters.accessToken = nil
        
        // Wait a moment then start fresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startSpotifyLogin()
        }
    }
}

// MARK: - Playback Control Functions
extension AppDelegate {
    func playSpotify() {
        appRemote.playerAPI?.resume { _, error in
            if let error = error {
                print("❌ Failed to play: \(error)")
            } else {
                print("✅ Resumed playback")
            }
        }
    }
    
    func pauseSpotify() {
        appRemote.playerAPI?.pause { _, error in
            if let error = error {
                print("❌ Failed to pause: \(error)")
            } else {
                print("✅ Paused playback")
            }
        }
    }
    
    func skipNext() {
        appRemote.playerAPI?.skip(toNext: { _, error in
            if let error = error {
                print("❌ Failed to skip next: \(error)")
            } else {
                print("✅ Skipped to next track")
            }
        })
    }
    
    func skipPrevious() {
        appRemote.playerAPI?.skip(toPrevious: { _, error in
            if let error = error {
                print("❌ Failed to skip previous: \(error)")
            } else {
                print("✅ Skipped to previous track")
            }
        })
    }
    
    /// Play a specific track (requires Spotify Premium)
    func playTrack(uri: String) {
        appRemote.playerAPI?.play(uri) { _, error in
            if let error = error {
                print("❌ Failed to play track \(uri): \(error)")
            } else {
                print("✅ Playing track: \(uri)")
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let spotifyDidConnect = Notification.Name("spotifyDidConnect")
    static let spotifyDidFail = Notification.Name("spotifyDidFail")
    static let spotifyRemoteDidConnect = Notification.Name("spotifyRemoteDidConnect")
    static let spotifyRemoteDidFail = Notification.Name("spotifyRemoteDidFail")
    static let spotifyRemoteDidDisconnect = Notification.Name("spotifyRemoteDidDisconnect")
    static let spotifyPlayerStateChanged = Notification.Name("spotifyPlayerStateChanged")
}

//
// MARK: - Required Info.plist Configuration
//
/*
Make sure your Info.plist includes these entries:

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.frequencyfinder.spotify</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>frequencyfinder</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>spotify</string>
</array>
*/

//
// MARK: - Key Requirements Based on Official Documentation
//

/*
1. ✅ Physical iOS device required (Spotify can't be installed on simulator)
2. ✅ Spotify app must be installed and user must be logged in
3. ✅ Music should be playing when connecting (iOS background app requirements)
4. ✅ Redirect URI in Spotify Dashboard must match exactly: frequencyfinder://callback
5. ✅ Bundle ID in Xcode must match what you registered in Spotify Dashboard
6. ✅ iOS 12+ deployment target required
7. ✅ -ObjC linker flag required in Build Settings
8. ✅ Bridging header must include: #import <SpotifyiOS/SpotifyiOS.h>

Common Issues:
- "No Active Device" = Start music in Spotify app first
- "Not Logged In" = Make sure user is signed into Spotify app
- "Connection Failed" = Check redirect URI matches dashboard exactly
- No callback received = Check Info.plist URL scheme setup
*/
