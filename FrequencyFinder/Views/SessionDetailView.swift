import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: VoiceSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Session at \(session.timestamp, formatter: dateFormatter)")
                    .font(.title)
                    .padding(.bottom, 10)

                // Pitch over time chart
                VStack(alignment: .leading) {
                    Text("Pitch Over Time")
                        .font(.headline)
                    if !session.pitchSamples.isEmpty {
                        Chart(Array(session.pitchSamples.enumerated()), id: \.offset) { index, pitch in
                            LineMark(
                                x: .value("Time", index),
                                y: .value("Pitch (Hz)", pitch)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                    } else {
                        Text("No pitch data available for this session.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                // Statistics
                VStack(alignment: .leading) {
                    Text("Statistics")
                        .font(.headline)
                    if !session.pitchSamples.isEmpty {
                        HStack {
                            StatisticView(name: "Mean", value: session.meanF0 ?? 0)
                            StatisticView(name: "Median", value: session.medianF0 ?? 0)
                            StatisticView(name: "Min", value: session.pitchSamples.min() ?? 0)
                            StatisticView(name: "Max", value: session.pitchSamples.max() ?? 0)
                        }
                    } else {
                        Text("No statistics available for this session.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct StatisticView: View {
    let name: String
    let value: Double

    var body: some View {
        VStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value, specifier: "%.1f") Hz")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}
