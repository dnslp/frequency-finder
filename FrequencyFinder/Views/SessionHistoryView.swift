import SwiftUI

struct SessionHistoryView: View {
    @ObservedObject var profileManager: UserProfileManager
    @State private var sessionToDelete: VoiceSession?
    @State private var deletionRationale: String = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            List {
                ForEach(profileManager.currentProfile.sessions.filter { !$0.isDeleted }) { session in
                    VStack(alignment: .leading) {
                        Text(session.notes ?? "Session")
                            .font(.headline)
                        Text("Date: \(session.timestamp, formatter: itemFormatter)")
                        Text(String(format: "Duration: %.1f seconds", session.duration))
                        if let medianF0 = session.medianF0 {
                            Text(String(format: "Median F0: %.1f Hz", medianF0))
                        }
                        if let meanF0 = session.meanF0 {
                            Text(String(format: "Mean F0: %.1f Hz", meanF0))
                        }
                    }
                }
                .onDelete(perform: promptDelete)
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
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
