//  SpotifyUserProfile.swift
//  FrequencyFinder
//

import Foundation

struct SpotifyUserProfile: Codable {
    let id: String
    let display_name: String?
    let email: String?
    let followers: SpotifyFollowers?
    let images: [SpotifyImage]?
    let country: String?
    let product: String?
}

struct SpotifyFollowers: Codable {
    let total: Int
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}
