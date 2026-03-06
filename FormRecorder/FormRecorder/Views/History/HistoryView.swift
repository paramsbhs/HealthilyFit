import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Workouts") {
                    Text("No workouts yet")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
