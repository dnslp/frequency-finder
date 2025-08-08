
//
//  SessionHistoryView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/30/25.
//

import SwiftUI

struct SessionHistoryView: View {
    @ObservedObject var profileManager: UserProfileManager
    @State private var sessionToDelete: VoiceSession?
    @State private var deletionRationale: String = ""
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: SessionFilter = .all
    @State private var selectedDateRange: DateRange = .all
    
    enum SessionFilter: String, CaseIterable {
        case all = "All"
        case goodQuality = "High Quality"
        case reading = "Reading"
        case centering = "Centering"
        case stretching = "Stretching"
    }
    
    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick Filters
                VStack(spacing: 12) {
                    HStack {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(SessionFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .font(.caption)
                    }
                    
                    HStack {
                        Picker("Date Range", selection: $selectedDateRange) {
                            ForEach(DateRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.caption)
                        
                        Spacer()
                        
                        Text("\(filteredSessions.count) sessions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Session List
                List {
                    ForEach(filteredSessions) { session in
                    VStack(alignment: .leading, spacing: 12) {
                        // Header with session type and pitch range indicators
                        HStack {
                            Text(session.notes ?? "Session")
                                .font(.headline)
                            
                            Spacer()
                            
                            // Pitch range indicator
                            if let medianF0 = session.medianF0 {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(pitchRangeColor(medianF0))
                                        .frame(width: 8, height: 8)
                                    Text(pitchRangeText(medianF0))
                                        .font(.caption2)
                                        .foregroundColor(pitchRangeColor(medianF0))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(pitchRangeColor(medianF0).opacity(0.1))
                                .cornerRadius(4)
                            }
                            
                            Text(sessionTypeText(session.type))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(sessionTypeColor(session.type).opacity(0.2))
                                .foregroundColor(sessionTypeColor(session.type))
                                .cornerRadius(4)
                        }

                        // Session metadata
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date: \(session.timestamp, formatter: itemFormatter)")
                                    .font(.subheadline)
                                Text(String(format: "Duration: %.1f seconds", session.duration))
                                    .font(.subheadline)
                            }
                            Spacer()
                        }
                        
                        // Pitch data quality indicators
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("📊 Data Quality")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading) {
                                        Text("\(session.pitchSamples.count)")
                                            .font(.title3.weight(.semibold))
                                            .foregroundColor(sampleCountColor(session.pitchSamples.count))
                                        Text("samples")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(String(format: "%.1f", samplesPerSecond(session)))
                                            .font(.title3.weight(.semibold))
                                            .foregroundColor(samplingRateColor(samplesPerSecond(session)))
                                        Text("samples/sec")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let coverage = dataCoverage(session) {
                                        VStack(alignment: .leading) {
                                            Text(String(format: "%.0f%%", coverage * 100))
                                                .font(.title3.weight(.semibold))
                                                .foregroundColor(coverageColor(coverage))
                                            Text("coverage")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                     }
                                }
                            }
                            Spacer()
                        }

                        // F0 Statistics with Sparkline
                        if session.medianF0 != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🎵 Pitch Analysis")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                                
                                // Pitch sparkline
                                if !session.pitchSamples.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        PitchSparkline(data: session.pitchSamples)
                                            .frame(height: 30)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(4)
                                        
                                        Text("Pitch contour over time")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Statistics row
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        if let medianF0 = session.medianF0 {
                                            Text(String(format: "%.1f Hz", medianF0))
                                                .font(.title3.weight(.semibold))
                                        }
                                        Text("Median F0")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let stdevF0 = session.stdevF0 {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(String(format: "%.1f Hz", stdevF0))
                                                .font(.title3.weight(.semibold))
                                                .foregroundColor(stabilityColor(stdevF0))
                                            Text("Stability")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if let minF0 = session.minF0, let maxF0 = session.maxF0 {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(String(format: "%.0f Hz", maxF0 - minF0))
                                                .font(.title3.weight(.semibold))
                                            Text("Range")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                    .onDelete(perform: promptDelete)
                }
            }
            .navigationTitle("Session History")
            .alert("Delete Session", isPresented: $showingDeleteAlert, actions: {
                TextField("Reason for deletion (e.g., too noisy)", text: $deletionRationale)
                Button("Delete", role: .destructive, action: deleteSession)
                Button("Cancel", role: .cancel, action: {})
            }, message: {
                Text("Are you sure you want to delete this session? Please provide a reason.")
            })
        }
    }

    private func promptDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            let allSessions = profileManager.currentProfile.sessions.filter { !$0.isDeleted }
            sessionToDelete = allSessions[index]
            showingDeleteAlert = true
        }
    }

    private func deleteSession() {
        guard let session = sessionToDelete else { return }
        if let index = profileManager.currentProfile.sessions.firstIndex(where: { $0.id == session.id }) {
            profileManager.currentProfile.sessions[index].isDeleted = true
            profileManager.currentProfile.sessions[index].deletionRationale = deletionRationale
            profileManager.saveProfileToDisk()
        }
        deletionRationale = ""
        sessionToDelete = nil
    }
    
    // MARK: - Filtering Logic
    
    var filteredSessions: [VoiceSession] {
        let allSessions = profileManager.currentProfile.sessions.filter { !$0.isDeleted }
        
        let dateFiltered = allSessions.filter { session in
            switch selectedDateRange {
            case .all:
                return true
            case .today:
                return Calendar.current.isDateInToday(session.timestamp)
            case .week:
                return Calendar.current.isDate(session.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
            case .month:
                return Calendar.current.isDate(session.timestamp, equalTo: Date(), toGranularity: .month)
            }
        }
        
        return dateFiltered.filter { session in
            switch selectedFilter {
            case .all:
                return true
            case .goodQuality:
                return session.pitchSamples.count >= 25 && (dataCoverage(session) ?? 0) >= 0.8
            case .reading:
                return session.type == .readingAnalysis
            case .centering:
                return session.type == .centering
            case .stretching:
                return session.type == .stretching
            }
        }
    }
    
    // MARK: - Data Quality Metrics
    
    private func samplesPerSecond(_ session: VoiceSession) -> Double {
        guard session.duration > 0 else { return 0 }
        return Double(session.pitchSamples.count) / session.duration
    }
    
    private func dataCoverage(_ session: VoiceSession) -> Double? {
        guard session.duration > 0 else { return nil }
        // Expected samples at 2 Hz (every 0.5 seconds)
        let expectedSamples = session.duration * 2.0
        return Double(session.pitchSamples.count) / expectedSamples
    }
    
    // MARK: - Color Coding Functions
    
    private func sessionTypeText(_ type: SessionType) -> String {
        switch type {
        case .readingAnalysis:
            return "Reading"
        case .centering:
            return "Centering"
        case .stretching:
            return "Stretching"
        }
    }
    
    private func sessionTypeColor(_ type: SessionType) -> Color {
        switch type {
        case .readingAnalysis:
            return .blue
        case .centering:
            return .green
        case .stretching:
            return .purple
        }
    }
    
    private func sampleCountColor(_ count: Int) -> Color {
        switch count {
        case 0...10: return .red
        case 11...25: return .orange
        default: return .green
        }
    }
    
    private func samplingRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0..<1.0: return .red
        case 1.0..<1.8: return .orange
        default: return .green
        }
    }
    
    private func coverageColor(_ coverage: Double) -> Color {
        switch coverage {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        default: return .green
        }
    }
    
    private func stabilityColor(_ stdev: Double) -> Color {
        switch stdev {
        case 0..<15.0: return .green    // Very stable
        case 15.0..<30.0: return .orange // Moderately stable  
        default: return .red            // Less stable
        }
    }
    
    // MARK: - Pitch Range Visualization
    
    private func pitchRangeColor(_ medianF0: Double) -> Color {
        switch medianF0 {
        case 0..<120: return .blue      // Low (bass/baritone)
        case 120..<180: return .green   // Medium-low (tenor/alto)
        case 180..<250: return .orange  // Medium-high (soprano)
        default: return .red            // High (child/falsetto)
        }
    }
    
    private func pitchRangeText(_ medianF0: Double) -> String {
        switch medianF0 {
        case 0..<120: return "Low"
        case 120..<180: return "Mid-Low"
        case 180..<250: return "Mid-High"
        default: return "High"
        }
    }
}

// MARK: - Pitch Sparkline Component
struct PitchSparkline: View {
    let data: [Double]
    
    var body: some View {
        Canvas { context, size in
            guard let normalizedData = normalizedData(), normalizedData.count > 1 else { return }
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height * (1 - normalizedData[0])))
            
            for i in 1..<normalizedData.count {
                let x = size.width * (CGFloat(i) / CGFloat(normalizedData.count - 1))
                let y = size.height * (1 - normalizedData[i])
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            context.stroke(path, with: .color(.accentColor), lineWidth: 1.5)
        }
    }
    
    private func normalizedData() -> [CGFloat]? {
        guard let min = data.min(), let max = data.max(), min != max else { return nil }
        return data.map { CGFloat(($0 - min) / (max - min)) }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

