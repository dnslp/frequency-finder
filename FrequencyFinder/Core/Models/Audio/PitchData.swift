//
//  PitchData.swift
//  FrequencyFinder
//
//  Created by David Nyman on 8/9/25.
//

import Foundation

struct PitchData: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let frequency: Float
    let note: String
    let cents: Float
    let amplitude: Float
    let confidence: Float
    
    init(timestamp: Date, frequency: Float, note: String, cents: Float, amplitude: Float, confidence: Float) {
        self.timestamp = timestamp
        self.frequency = frequency
        self.note = note
        self.cents = cents
        self.amplitude = amplitude
        self.confidence = confidence
    }
}