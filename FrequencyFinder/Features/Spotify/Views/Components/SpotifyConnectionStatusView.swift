//
//  SpotifyConnectionStatusView.swift
//  FrequencyFinder
//
//  Spotify connection status header component
//

import SwiftUI

struct SpotifyConnectionStatusView: View {
    @ObservedObject var manager: SpotifyManager
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.spotifyLightGray)
            
            Spacer()
            
            if manager.isAuthenticated {
                Text(manager.cacheStatusText)
                    .font(.caption)
                    .foregroundColor(.spotifyLightGray)
            }
            
            // Sync button
            if manager.isAuthenticated && manager.syncStatus.canSync {
                Button(action: manager.syncAllData) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.spotifyGreen)
                }
                .disabled(!manager.syncStatus.canSync)
            } else if case .syncing = manager.syncStatus {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .spotifyGreen))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.spotifyDarkGray.opacity(0.6))
    }
    
    private var statusText: String {
        if manager.isOfflineMode {
            return "Offline Mode"
        } else if manager.isAuthenticated {
            return manager.syncStatus.displayText
        } else {
            return "Not connected"
        }
    }
    
    private var statusColor: Color {
        if manager.isOfflineMode {
            return .orange
        } else if manager.isAuthenticated {
            switch manager.syncStatus {
            case .idle, .success: return .spotifyGreen
            case .syncing: return .spotifyGreen.opacity(0.7)
            case .error, .partialFailure: return .red
            }
        } else {
            return .red
        }
    }
}