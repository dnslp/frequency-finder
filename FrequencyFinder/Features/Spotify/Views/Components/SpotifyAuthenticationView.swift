//
//  SpotifyAuthenticationView.swift
//  FrequencyFinder
//
//  Spotify authentication screen component
//

import SwiftUI

struct SpotifyAuthenticationView: View {
    @ObservedObject var manager: SpotifyManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.spotifyGreen)
                
                Text("Connect to Spotify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.spotifyWhite)
                
                Text("Get insights into your music taste with artists, tracks, playlists, and listening history. Data is cached locally for offline viewing!")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.spotifyLightGray)
                    .font(.body)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
                if manager.isLoading {
                    ProgressView("Connecting...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .spotifyGreen))
                        .foregroundColor(.spotifyWhite)
                        .frame(height: 50)
                } else {
                    Button("Connect to Spotify") {
                        manager.authenticate()
                    }
                    .font(.headline)
                    .foregroundColor(.spotifyBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(LinearGradient.spotifyGreenGradient)
                    )
                    .padding(.horizontal, 40)
                }
                
                if let error = manager.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.spotifyBlack)
    }
}