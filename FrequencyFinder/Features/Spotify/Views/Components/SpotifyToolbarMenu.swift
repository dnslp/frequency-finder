//
//  SpotifyToolbarMenu.swift
//  FrequencyFinder
//
//  Toolbar menu for Spotify actions
//

import SwiftUI

struct SpotifyToolbarMenu: View {
    @ObservedObject var manager: SpotifyManager
    
    var body: some View {
        Menu {
            if manager.isAuthenticated {
                Button(action: manager.forceSync) {
                    Label("Refresh Data", systemImage: "arrow.clockwise")
                }
                .disabled(!manager.syncStatus.canSync)
                
                Button(action: manager.clearAllData) {
                    Label("Clear Cache", systemImage: "trash")
                }
                
                Divider()
                
                Button(role: .destructive, action: manager.logout) {
                    Label("Disconnect", systemImage: "xmark.circle")
                }
            } else if manager.hasOfflineData {
                Button(action: manager.clearAllData) {
                    Label("Clear Cache", systemImage: "trash")
                }
                
                Button(action: manager.authenticate) {
                    Label("Connect to Spotify", systemImage: "music.note.house")
                }
            } else {
                Button(action: manager.authenticate) {
                    Label("Connect to Spotify", systemImage: "music.note.house")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}