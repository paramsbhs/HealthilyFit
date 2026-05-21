import CoreData
import Foundation
import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        List {
            Section("Summary") {
                detailRow(label: "Exercise", value: workout.exerciseType.capitalized)
                detailRow(label: "Date", value: workout.date.formatted(date: .abbreviated, time: .shortened))
                detailRow(label: "Total Reps", value: "\(workout.totalReps)")
                detailRow(label: "Form Score", value: String(format: "%.2f", workout.formScore))
            }

            Section("Sets") {
                ForEach(workout.sortedSets) { set in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(set.reps)/\(set.targetReps) reps")
                            .font(.headline)
                        Text(set.completedAt.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Form: \(String(format: "%.2f", set.formScore))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Workout Details")
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = Workout.fetchRequest()
    let previewWorkout: Workout
    if let existing = try? context.fetch(request).first {
        previewWorkout = existing
    } else {
        let workout = Workout(context: context)
        workout.id = UUID()
        workout.date = Date()
        workout.exerciseType = "squat"
        workout.totalReps = 12
        workout.formScore = 0.8
        previewWorkout = workout
    }

    return NavigationStack {
        WorkoutDetailView(workout: previewWorkout)
    }
}
