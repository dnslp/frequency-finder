import SwiftUI

struct SessionHistoryView: View {
    @ObservedObject var profileManager: UserProfileManager

    var body: some View {
        NavigationView {
            List(profileManager.currentProfile.sessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    VStack(alignment: .leading) {
                        Text("Session at \(session.timestamp, formatter: dateFormatter)")
                            .font(.headline)
                        Text("Duration: \(session.duration, specifier: "%.1f")s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Session History")
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
