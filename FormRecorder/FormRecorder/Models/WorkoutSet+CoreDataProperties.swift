import CoreData
import Foundation

extension WorkoutSet {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSet> {
        NSFetchRequest<WorkoutSet>(entityName: "WorkoutSet")
    }

    @NSManaged public var id: UUID
    @NSManaged public var completedAt: Date
    @NSManaged public var exerciseType: String
    @NSManaged public var reps: Int32
    @NSManaged public var targetReps: Int32
    @NSManaged public var formScore: Double
    @NSManaged public var workout: Workout?
}

extension WorkoutSet: Identifiable {
}
