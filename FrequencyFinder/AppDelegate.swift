
//
// AppDelegate.swift
// FrequencyFinder
//
// Created by David Nyman on 7/27/25.
//

import UIKit
import SpotifyiOS

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Spotify Objects
    var appRemote: SPTAppRemote!
    var sessionManager: SPTSessionManager!

    let clientID    = "7c5840c8370940a6be5a12336241f464"
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

        // Reuse saved token if present
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            appRemote.connectionParameters.accessToken = token
            appRemote.connect()
        }

        return true
    }

    /// Call this from your UI to start the Spotify OAuth flow
    func startSpotifyLogin() {
        let scopes: SPTScope = [.appRemoteControl, .userReadPrivate, .userReadEmail]
        // Initiate the PKCE-based Authorization Code flow, pass nil for campaign
        sessionManager.initiateSession(with: scopes, options: .default, campaign: nil)
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Forward the URL to the Session Manager
        sessionManager.application(app, open: url, options: options)
        return true
    }
}

// MARK: - SPTSessionManagerDelegate
extension AppDelegate: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        // Save and apply the new access token
        UserDefaults.standard.set(session.accessToken, forKey: tokenKey)
        appRemote.connectionParameters.accessToken = session.accessToken
        // Connect App-Remote now that we have a token
        appRemote.connect()
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Spotify auth failed:", error)
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        // Update token on renew
        UserDefaults.standard.set(session.accessToken, forKey: tokenKey)
        appRemote.connectionParameters.accessToken = session.accessToken
    }
}

// MARK: - SPTAppRemoteDelegate
extension AppDelegate: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        // Subscribe to player state updates
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error = error {
                print("⚠️ Subscription error:", error)
            }
        })
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("❌ AppRemote failed to connect:", error ?? "unknown error")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("⚠️ AppRemote disconnected:", error ?? "no error")
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate
extension AppDelegate: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("▶️ Now playing:", playerState.track.name)
    }
}
