import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager: UserProfileManager
    @Binding var showOnboarding: Bool
    @State private var selectedMetric = "pitch"
    @State private var showingSettings = false
    
    private var profile: UserProfile {
        profileManager.currentProfile
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Section
                    VoiceProfileHeaderView(profile: profile)
                    
                    // Key Metrics Dashboard
                    MetricsDashboardView(profile: profile)
                    
                    // Progress & Streaks
                    ProgressStreakView(profile: profile)
                    
                    // Session Activity
                    SessionActivityView(profileManager: profileManager)
                    
                    // Voice Range Analysis
                    VoiceRangeAnalysisView(profile: profile)
                    
                    // Chart Section (Simplified)
                    SimplifiedChartsView(profileManager: profileManager)
                    
                    // Quick Actions
                    QuickActionsView(profileManager: profileManager, showOnboarding: $showOnboarding)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Voice Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ProfileSettingsView(profileManager: profileManager, showOnboarding: $showOnboarding)
            }
        }
    }
}

// MARK: - Header Section
struct VoiceProfileHeaderView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Text("🎤")
                        .font(.system(size: 40))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Voice Profile")
                        .font(.title2.bold())
                    Text("Goal: \(profile.preferences.voiceGoal ?? "Vocal Wellness")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Flow: \(profile.preferences.flowType.rawValue.capitalized)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Metrics Dashboard
struct MetricsDashboardView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Key Metrics")
                .font(.headline.bold())
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "Average Pitch (f₀)",
                    value: "\(Int(profile.calculatedF0?.rounded() ?? 0)) Hz",
                    subtitle: voiceRangeDescription(for: profile.vocalRange),
                    color: .blue,
                    icon: "waveform"
                )
                
                MetricCard(
                    title: "Pitch Stability",
                    value: "±\(Int(profile.f0StabilityScore?.rounded() ?? 0)) Hz",
                    subtitle: stabilityDescription(profile.f0StabilityScore ?? 0),
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                MetricCard(
                    title: "Total Sessions",
                    value: "\(profile.analytics.totalSessionCount)",
                    subtitle: "\(formatTime(profile.analytics.totalDuration)) recorded",
                    color: .orange,
                    icon: "mic.circle.fill"
                )
                
                MetricCard(
                    title: "Current Streak",
                    value: "\(profile.analytics.streakDays)",
                    subtitle: streakDescription(profile.analytics.streakDays),
                    color: .red,
                    icon: "flame.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func voiceRangeDescription(for range: VocalRange) -> String {
        switch range {
        case .bass: return "Deep & Resonant"
        case .baritone: return "Rich & Warm"
        case .tenor: return "Bright & Clear"
        case .alto: return "Smooth & Mellow"
        case .soprano: return "Light & Airy"
        case .undefined: return "Discovering..."
        case .mezzoSoprano: return "Rich & Expressive"
        }
    }
    
    private func stabilityDescription(_ stability: Double) -> String {
        switch stability {
        case 0..<10: return "Very Stable"
        case 10..<20: return "Stable"
        case 20..<30: return "Moderate"
        default: return "Variable"
        }
    }
    
    private func streakDescription(_ days: Int) -> String {
        switch days {
        case 0: return "Start today!"
        case 1: return "Great start!"
        case 2...6: return "Building momentum"
        case 7...29: return "Strong habit!"
        default: return "Amazing consistency!"
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return minutes > 60 ? "\(minutes/60)h \(minutes%60)m" : "\(minutes)m"
    }
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Progress & Streak View
struct ProgressStreakView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🔥 Progress & Streaks")
                .font(.headline.bold())
            
            HStack(spacing: 20) {
                // Streak Visualization
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: min(Double(profile.analytics.streakDays) / 30.0, 1.0))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(profile.analytics.streakDays)")
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                    }
                    
                    Text("Day Streak")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ProgressRow(title: "Weekly Goal", progress: weeklyProgress(profile), color: .blue)
                    ProgressRow(title: "Monthly Goal", progress: monthlyProgress(profile), color: .green)
                    ProgressRow(title: "Voice Stability", progress: stabilityProgress(profile), color: .purple)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func weeklyProgress(_ profile: UserProfile) -> Double {
        let weekSessions = profile.sessions.filter { session in
            Calendar.current.isDate(session.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        return min(Double(weekSessions) / 7.0, 1.0)
    }
    
    private func monthlyProgress(_ profile: UserProfile) -> Double {
        let monthSessions = profile.sessions.filter { session in
            Calendar.current.isDate(session.timestamp, equalTo: Date(), toGranularity: .month)
        }.count
        return min(Double(monthSessions) / 20.0, 1.0)
    }
    
    private func stabilityProgress(_ profile: UserProfile) -> Double {
        guard let stability = profile.f0StabilityScore else { return 0 }
        return max(0, min(1.0, (30 - stability) / 30.0))
    }
}

// MARK: - Progress Row Component
struct ProgressRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 0.5)
        }
    }
}

// MARK: - Session Activity
struct SessionActivityView: View {
    @ObservedObject var profileManager: UserProfileManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🎙️ Recent Activity")
                    .font(.headline.bold())
                Spacer()
                NavigationLink(destination: SessionHistoryView(profileManager: profileManager)) {
                    Text("View All")
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                }
            }
            
            if profileManager.currentProfile.sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No sessions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Start your first voice session to see activity here!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(profileManager.currentProfile.sessions.prefix(3)) { session in
                    SessionRowView(session: session)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Session Row Component
struct SessionRowView: View {
    let session: VoiceSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Session Type Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(sessionColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: sessionIcon)
                    .foregroundColor(sessionColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionTypeText)
                    .font(.subheadline.bold())
                
                Text(session.notes ?? "Voice Session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(formatDuration(session.duration)) • \(session.pitchSamples.count) samples")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(session.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var sessionColor: Color {
        switch session.type {
        case .centering: return .blue
        case .readingAnalysis: return .green
        case .stretching: return .orange
        }
    }
    
    private var sessionIcon: String {
        switch session.type {
        case .centering: return "tuningfork"
        case .readingAnalysis: return "book.fill"
        case .stretching: return "waveform"
        }
    }
    
    private var sessionTypeText: String {
        switch session.type {
        case .centering: return "Centering"
        case .readingAnalysis: return "Reading"
        case .stretching: return "Stretching"
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}

// MARK: - Voice Range Analysis
struct VoiceRangeAnalysisView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎵 Voice Range Analysis")
                .font(.headline.bold())
            
            if let range = profile.pitchRange {
                VStack(spacing: 12) {
                    // Range Visualization
                    VoiceRangeVisualization(
                        currentRange: range,
                        averagePitch: profile.calculatedF0 ?? 0,
                        vocalRange: profile.vocalRange
                    )
                    
                    // Range Details
                    HStack {
                        RangeDetail(
                            title: "Lowest",
                            value: "\(Int(range.lowerBound.rounded())) Hz",
                            color: .blue
                        )
                        
                        Spacer()
                        
                        RangeDetail(
                            title: "Average",
                            value: "\(Int(profile.calculatedF0?.rounded() ?? 0)) Hz",
                            color: .green
                        )
                        
                        Spacer()
                        
                        RangeDetail(
                            title: "Highest",
                            value: "\(Int(range.upperBound.rounded())) Hz",
                            color: .orange
                        )
                    }
                }
            } else {
                Text("Record more sessions to see your voice range analysis!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Voice Range Visualization
struct VoiceRangeVisualization: View {
    let currentRange: ClosedRange<Double>
    let averagePitch: Double
    let vocalRange: VocalRange
    
    private let minFreq: Double = 80
    private let maxFreq: Double = 400
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                
                // Range indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .green, .orange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(
                        width: rangeWidth(in: geometry.size.width),
                        height: 8
                    )
                    .offset(x: rangeOffset(in: geometry.size.width))
                
                // Average pitch indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
                    .offset(x: averageOffset(in: geometry.size.width) - 8)
            }
        }
        .frame(height: 20)
    }
    
    private func rangeWidth(in totalWidth: CGFloat) -> CGFloat {
        let normalizedWidth = (currentRange.upperBound - currentRange.lowerBound) / (maxFreq - minFreq)
        return totalWidth * CGFloat(normalizedWidth)
    }
    
    private func rangeOffset(in totalWidth: CGFloat) -> CGFloat {
        let normalizedOffset = (currentRange.lowerBound - minFreq) / (maxFreq - minFreq)
        return totalWidth * CGFloat(normalizedOffset)
    }
    
    private func averageOffset(in totalWidth: CGFloat) -> CGFloat {
        let normalizedOffset = (averagePitch - minFreq) / (maxFreq - minFreq)
        return totalWidth * CGFloat(normalizedOffset)
    }
}

// MARK: - Range Detail Component
struct RangeDetail: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
}

// MARK: - Simplified Charts View
struct SimplifiedChartsView: View {
    @ObservedObject var profileManager: UserProfileManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📈 Voice Analytics")
                .font(.headline.bold())
            
            // Use existing F0TrendChartView instead of Charts framework
            F0TrendChartView(profileManager: profileManager)
                .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    @ObservedObject var profileManager: UserProfileManager
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚡ Quick Actions")
                .font(.headline.bold())
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ActionButton(
                    title: "Retake Onboarding",
                    subtitle: "Update your goals",
                    icon: "person.crop.circle.badge.questionmark",
                    color: .blue
                ) {
                    profileManager.hasCompletedOnboarding = false
                    showOnboarding = true
                }
                
                ActionButton(
                    title: "Export Data",
                    subtitle: "Share your progress",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    // TODO: Implement data export
                }
                
                NavigationLink(destination: SessionHistoryView(profileManager: profileManager)) {
                    ActionButtonView(
                        title: "Session History",
                        subtitle: "View all recordings",
                        icon: "clock.arrow.circlepath",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: SpotifyView()) {
                    ActionButtonView(
                        title: "Spotify Data",
                        subtitle: "Music insights",
                        icon: "music.note.house",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Action Button Components
struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ActionButtonView(title: title, subtitle: subtitle, icon: icon, color: color)
        }
    }
}

struct ActionButtonView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Settings Sheet
struct ProfileSettingsView: View {
    @ObservedObject var profileManager: UserProfileManager
    @Binding var showOnboarding: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Preferences") {
                    Picker("Flow Type", selection: $profileManager.currentProfile.preferences.flowType) {
                        ForEach(FlowType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized)
                        }
                    }
                    
                    Toggle("Reminders", isOn: $profileManager.currentProfile.preferences.reminderEnabled)
                    
                    if profileManager.currentProfile.preferences.reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: Binding(
                                get: { profileManager.currentProfile.preferences.preferredReminderTime ?? Date() },
                                set: { profileManager.currentProfile.preferences.preferredReminderTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                Section("Data") {
                    Button("Reset Profile", role: .destructive) {
                        profileManager.resetProfile()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}