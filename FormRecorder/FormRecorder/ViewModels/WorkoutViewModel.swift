import Combine
import CoreData
import Foundation

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []

    private var viewContext: NSManagedObjectContext?

    func setContext(_ context: NSManagedObjectContext) {
        guard viewContext !== context else {
            return
        }
        viewContext = context
        fetchWorkouts()
    }

    func fetchWorkouts() {
        guard let viewContext else {
            return
        }

        let request = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]

        do {
            workouts = try viewContext.fetch(request)
        } catch {
            workouts = []
        }
    }

    func saveWorkout(exerciseType: ExerciseType, reps: Int, targetReps: Int, formScore: Double) {
        guard let viewContext, reps > 0 else {
            return
        }

        let timestamp = Date()
        let workout = Workout(context: viewContext)
        workout.id = UUID()
        workout.date = timestamp
        workout.exerciseType = exerciseType.rawValue
        workout.totalReps = Int32(reps)
        workout.formScore = formScore

        let set = WorkoutSet(context: viewContext)
        set.id = UUID()
        set.completedAt = timestamp
        set.exerciseType = exerciseType.rawValue
        set.reps = Int32(reps)
        set.targetReps = Int32(targetReps)
        set.formScore = formScore
        set.workout = workout
        workout.addToSets(set)

        persistChanges()
        fetchWorkouts()
    }

    func deleteWorkouts(at offsets: IndexSet) {
        guard let viewContext else {
            return
        }

        offsets.map { workouts[$0] }.forEach(viewContext.delete)
        persistChanges()
        fetchWorkouts()
    }

    private func persistChanges() {
        guard let viewContext, viewContext.hasChanges else {
            return
        }

        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
        }
    }
}
