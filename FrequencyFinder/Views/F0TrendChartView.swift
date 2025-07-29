//
//  F0TrendChartView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//


import SwiftUI
import Charts

struct VocalRangeBand: Identifiable {
    let id = UUID()
    let name: String
    let range: ClosedRange<Double>
    let color: Color
}

let vocalRangeBands: [VocalRangeBand] = [
    VocalRangeBand(name: "Bass", range: 50...82, color: .blue.opacity(0.2)),
    VocalRangeBand(name: "Baritone", range: 82...98, color: .indigo.opacity(0.2)),
    VocalRangeBand(name: "Tenor", range: 98...165, color: .green.opacity(0.2)),
    VocalRangeBand(name: "Alto", range: 165...247, color: .yellow.opacity(0.2)),
    VocalRangeBand(name: "Mezzo", range: 247...349, color: .orange.opacity(0.2)),
    VocalRangeBand(name: "Soprano", range: 349...1000, color: .red.opacity(0.2))
]


struct F0TrendChartView: View {
    @ObservedObject var profileManager: UserProfileManager

    var f0Sessions: [VoiceSession] {
        profileManager.currentProfile.sessions
            .filter { $0.type == .readingAnalysis && $0.medianF0 != nil }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("📈 Fundamental Frequency Over Time")
                .font(.headline)
                .padding(.bottom, 4)

            if f0Sessions.isEmpty {
                Text("No reading analysis sessions yet.")
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    // Add background bands first
                    ForEach(vocalRangeBands) { band in
                        RectangleMark(
                            xStart: .value("Start", f0Sessions.first?.timestamp ?? Date()),
                            xEnd: .value("End", f0Sessions.last?.timestamp ?? Date()),
                            yStart: .value("Min", band.range.lowerBound),
                            yEnd: .value("Max", band.range.upperBound)
                        )
                        .foregroundStyle(band.color)
                        .opacity(0.4)
                    }

                    // Add the f₀ line
                    ForEach(f0Sessions, id: \.id) { session in
                        LineMark(
                            x: .value("Date", session.timestamp),
                            y: .value("f₀ (Hz)", session.medianF0 ?? 0)
                        )
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle())
                        .foregroundStyle(.primary)
                    }
                }
                .chartYScale(domain: autoDomain())
                .frame(height: 250)

            }
        }
        .padding()
    }

    // Optional: auto-scale chart domain
    func autoDomain() -> ClosedRange<Double> {
        let values = f0Sessions.compactMap { $0.medianF0 }
        guard let min = values.min(), let max = values.max() else {
            return 50...300
        }
        return (min - 10)...(max + 10)
    }
}
