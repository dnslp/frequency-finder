import Foundation

class SpotifyManager: NSObject, ObservableObject {
    let spotifyClientID = "7c5840c8370940a6be5a12336241f464"
    let spotifyRedirectURL = URL(string: "frequency-finder://spotify-login-callback")!

    @Published var accessToken: String?
    @Published var username: String?

    lazy var configuration = SPTConfiguration(
        clientID: spotifyClientID,
        redirectURL: spotifyRedirectURL
    )

    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()

    func connect() {
        if let _ = self.appRemote.connectionParameters.accessToken {
            self.appRemote.connect()
        } else {
            self.appRemote.authorizeAndPlayURI("")
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        let parameters = appRemote.authorizationParameters(from: url)

        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = accessToken
            self.accessToken = accessToken
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("Error connecting to spotify: \(errorDescription)")
        }
    }
}

extension SpotifyManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        })
        fetchUserProfile()
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Failed to connect to Spotify: \(error?.localizedDescription ?? "unknown error")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Disconnected from Spotify: \(error?.localizedDescription ?? "unknown error")")
    }

    func fetchUserProfile() {
        appRemote.userAPI?.fetchCapabilities(callback: { (capabilities, error) in
            if let error = error {
                print("Error fetching user capabilities: \(error.localizedDescription)")
                return
            }
            guard let capabilities = capabilities as? SPTAppRemoteUserCapabilities else { return }
            self.appRemote.userAPI?.fetchUserCapabilities(callback: { (user, error) in
                if let error = error {
                    print("Error fetching user profile: \(error.localizedDescription)")
                    return
                }
                self.username = user?.displayName
            })
        })
    }
}

extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        //
    }
}
