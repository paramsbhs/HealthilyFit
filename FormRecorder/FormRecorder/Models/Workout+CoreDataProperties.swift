import CoreData
import Foundation

extension Workout {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        NSFetchRequest<Workout>(entityName: "Workout")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var exerciseType: String
    @NSManaged public var notes: String?
    @NSManaged public var totalReps: Int32
    @NSManaged public var formScore: Double
    @NSManaged public var sets: Set<WorkoutSet>?
}

extension Workout {
    var sortedSets: [WorkoutSet] {
        (sets ?? []).sorted { $0.completedAt < $1.completedAt }
    }

    var summary: WorkoutSummary {
        let totalSetReps = sortedSets.reduce(0) { $0 + Int($1.reps) }
        let averageForm = sortedSets.isEmpty ? formScore : sortedSets.map(\.formScore).reduce(0, +) / Double(sortedSets.count)

        return WorkoutSummary(
            id: id,
            date: date,
            exerciseType: exerciseType,
            totalReps: totalSetReps == 0 ? Int(totalReps) : totalSetReps,
            averageFormScore: averageForm,
            setCount: sortedSets.count
        )
    }
}

extension Workout: Identifiable {
}

extension Workout {
    @objc(addSetsObject:)
    @NSManaged public func addToSets(_ value: WorkoutSet)

    @objc(removeSetsObject:)
    @NSManaged public func removeFromSets(_ value: WorkoutSet)

    @objc(addSets:)
    @NSManaged public func addToSets(_ values: NSSet)

    @objc(removeSets:)
    @NSManaged public func removeFromSets(_ values: NSSet)
}
