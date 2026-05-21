import Foundation

struct WorkoutSummary: Identifiable {
    let id: UUID
    let date: Date
    let exerciseType: String
    let totalReps: Int
    let averageFormScore: Double
    let setCount: Int
}
