import Combine
import Foundation

final class FormViewModel: ObservableObject {
    @Published private(set) var feedbackMessages: [String] = []
    @Published private(set) var formScore: Double = 0

    private let analyzer = FormAnalyzer()
    private var scoreAccumulator: Double = 0
    private var sampleCount: Int = 0

    func setExercise(_ exercise: ExerciseType) {
        _ = exercise
        feedbackMessages = []
        formScore = 0
        scoreAccumulator = 0
        sampleCount = 0
    }

    func startSet(exercise: ExerciseType) {
        _ = exercise
        scoreAccumulator = 0
        sampleCount = 0
        formScore = 0
    }

    func stopSet() {
        guard sampleCount > 0 else {
            return
        }
        formScore = scoreAccumulator / Double(sampleCount)
    }

    func process(joints: [Joint], exercise: ExerciseType, isTracking: Bool) {
        let analysis = analyzer.analyze(exercise: exercise, joints: joints)
        feedbackMessages = analysis.feedbackMessages

        guard isTracking else {
            return
        }

        scoreAccumulator += analysis.score
        sampleCount += 1
        formScore = scoreAccumulator / Double(sampleCount)
    }
}
