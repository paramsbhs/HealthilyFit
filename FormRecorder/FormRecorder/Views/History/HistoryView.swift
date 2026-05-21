import CoreData
import Foundation
import SwiftUI

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var workoutViewModel = WorkoutViewModel()

    var body: some View {
        NavigationStack {
            List {
                if workoutViewModel.workouts.isEmpty {
                    Text("No workouts yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(workoutViewModel.workouts) { workout in
                        NavigationLink {
                            WorkoutDetailView(workout: workout)
                        } label: {
                            workoutRow(for: workout.summary)
                        }
                    }
                    .onDelete(perform: workoutViewModel.deleteWorkouts)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .onAppear {
                workoutViewModel.setContext(viewContext)
            }
        }
    }

    private func workoutRow(for summary: WorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.exerciseType.capitalized)
                .font(.headline)
            Text(summary.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(summary.totalReps) reps • form \(String(format: "%.2f", summary.averageFormScore))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
