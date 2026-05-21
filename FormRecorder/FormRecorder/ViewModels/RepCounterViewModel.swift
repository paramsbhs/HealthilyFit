import Combine
import Foundation

final class RepCounterViewModel: ObservableObject {
    @Published var selectedExercise: ExerciseType = .squat
    @Published private(set) var repCount = 0
    @Published private(set) var phase: RepPhase = .top
    @Published private(set) var isTracking = false
    @Published private(set) var completionMessage: String?

    let targetReps: Int

    private let repCounter: RepCounter

    init(targetReps: Int = 12) {
        self.targetReps = targetReps
        self.repCounter = RepCounter(exerciseType: .squat)
    }

    func selectExercise(_ exercise: ExerciseType) {
        repCounter.configure(exerciseType: exercise)
        repCount = 0
        phase = .top
        completionMessage = nil
        isTracking = false
    }

    func startSet() {
        repCounter.configure(exerciseType: selectedExercise)
        repCount = 0
        phase = .top
        completionMessage = nil
        isTracking = true
    }

    func stopSet() {
        isTracking = false
    }

    func process(joints: [Joint]) {
        guard isTracking else {
            return
        }

        let update = repCounter.process(joints: joints)
        repCount = update.count
        phase = update.phase

        if repCount >= targetReps {
            isTracking = false
            completionMessage = "Good set!"
        }
    }
}
