import Combine
import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
    @Published private(set) var weeklyTotalReps: Int = 0
    @Published private(set) var weeklyAverageFormScore: Double = 0

    func refresh(with workouts: [Workout]) {
        let calendar = Calendar.current
        let now = Date()

        let weekWorkouts = workouts.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .yearForWeekOfYear)
        }

        weeklyTotalReps = weekWorkouts.reduce(0) { $0 + Int($1.totalReps) }

        if weekWorkouts.isEmpty {
            weeklyAverageFormScore = 0
        } else {
            let sum = weekWorkouts.reduce(0) { $0 + $1.formScore }
            weeklyAverageFormScore = sum / Double(weekWorkouts.count)
        }
    }
}
