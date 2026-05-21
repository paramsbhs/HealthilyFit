import CoreData
import Foundation
import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var statsViewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                statCard(
                    title: "This Week",
                    value: "\(statsViewModel.weeklyTotalReps) reps",
                    subtitle: "Total reps completed"
                )

                statCard(
                    title: "Avg Form",
                    value: String(format: "%.2f", statsViewModel.weeklyAverageFormScore),
                    subtitle: "Average set quality (0.00-1.00)"
                )

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .onAppear {
                workoutViewModel.setContext(viewContext)
                statsViewModel.refresh(with: workoutViewModel.workouts)
            }
            .onChange(of: workoutViewModel.workouts) { _, workouts in
                statsViewModel.refresh(with: workouts)
            }
        }
    }

    private func statCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
