//
//  TuningSession.swift
//  FrequencyFinder
//
//  Created by David Nyman on 8/9/25.
//

import Foundation
import Combine

class TuningSession: ObservableObject, Codable {
    @Published var pitchHistory: [PitchData] = []
    @Published var sessionStartTime: Date = Date()
    @Published var isRecording: Bool = false
    
    private let maxHistoryCount: Int = 1000 // Limit history to prevent memory issues
    
    enum CodingKeys: CodingKey {
        case pitchHistory
        case sessionStartTime
        case isRecording
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pitchHistory = try container.decode([PitchData].self, forKey: .pitchHistory)
        sessionStartTime = try container.decode(Date.self, forKey: .sessionStartTime)
        isRecording = try container.decode(Bool.self, forKey: .isRecording)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pitchHistory, forKey: .pitchHistory)
        try container.encode(sessionStartTime, forKey: .sessionStartTime)
        try container.encode(isRecording, forKey: .isRecording)
    }
    
    func addPitchData(_ pitchData: PitchData) {
        DispatchQueue.main.async {
            self.pitchHistory.append(pitchData)
            
            // Trim history if it gets too long
            if self.pitchHistory.count > self.maxHistoryCount {
                self.pitchHistory.removeFirst(self.pitchHistory.count - self.maxHistoryCount)
            }
        }
    }
    
    func startNewSession() {
        DispatchQueue.main.async {
            self.pitchHistory.removeAll()
            self.sessionStartTime = Date()
            self.isRecording = true
        }
    }
    
    func stopSession() {
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.pitchHistory.removeAll()
        }
    }
    
    // MARK: - Analytics
    
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }
    
    var averageFrequency: Float {
        guard !pitchHistory.isEmpty else { return 0 }
        let sum = pitchHistory.reduce(0) { $0 + $1.frequency }
        return sum / Float(pitchHistory.count)
    }
    
    var mostCommonNote: String {
        guard !pitchHistory.isEmpty else { return "" }
        
        let noteCounts = pitchHistory.reduce(into: [:]) { counts, pitchData in
            counts[pitchData.note, default: 0] += 1
        }
        
        return noteCounts.max { $0.value < $1.value }?.key ?? ""
    }
    
    var averageAccuracy: Float {
        guard !pitchHistory.isEmpty else { return 0 }
        let totalCentsDeviation = pitchHistory.reduce(0) { $0 + abs($1.cents) }
        let averageCentsDeviation = totalCentsDeviation / Float(pitchHistory.count)
        // Convert cents deviation to accuracy percentage (100 cents = semitone)
        return max(0, 100 - averageCentsDeviation)
    }
}