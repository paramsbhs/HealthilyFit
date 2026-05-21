import Foundation

enum ExerciseType: String, CaseIterable, Identifiable {
    case squat
    case pushup

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .squat:
            return "Squat"
        case .pushup:
            return "Push-Up"
        }
    }
}
