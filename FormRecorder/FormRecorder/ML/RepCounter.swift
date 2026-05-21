import CoreGraphics
import Foundation

enum RepPhase: String {
    case top = "Top"
    case bottom = "Bottom"
}

struct RepCounterUpdate {
    let count: Int
    let phase: RepPhase
    let didCompleteRep: Bool
}

final class RepCounter {
    private(set) var exerciseType: ExerciseType
    private(set) var count = 0
    private(set) var phase: RepPhase = .top

    private let minimumRepInterval: TimeInterval = 0.35
    private var lastRepTimestamp: Date?

    init(exerciseType: ExerciseType) {
        self.exerciseType = exerciseType
    }

    func configure(exerciseType: ExerciseType) {
        self.exerciseType = exerciseType
        reset()
    }

    func reset() {
        count = 0
        phase = .top
        lastRepTimestamp = nil
    }

    func process(joints: [Joint], timestamp: Date = Date()) -> RepCounterUpdate {
        let metric = movementMetric(from: joints)

        guard let metric else {
            return RepCounterUpdate(count: count, phase: phase, didCompleteRep: false)
        }

        let downThreshold: CGFloat
        let upThreshold: CGFloat

        switch exerciseType {
        case .squat:
            downThreshold = 105
            upThreshold = 155
        case .pushup:
            downThreshold = 95
            upThreshold = 150
        }

        var didCompleteRep = false

        switch phase {
        case .top:
            if metric < downThreshold {
                phase = .bottom
            }
        case .bottom:
            if metric > upThreshold {
                if canCountRep(at: timestamp) {
                    count += 1
                    didCompleteRep = true
                    lastRepTimestamp = timestamp
                }
                phase = .top
            }
        }

        return RepCounterUpdate(count: count, phase: phase, didCompleteRep: didCompleteRep)
    }

    private func canCountRep(at timestamp: Date) -> Bool {
        guard let lastRepTimestamp else {
            return true
        }
        return timestamp.timeIntervalSince(lastRepTimestamp) >= minimumRepInterval
    }

    private func movementMetric(from joints: [Joint]) -> CGFloat? {
        switch exerciseType {
        case .squat:
            return averageKneeAngle(from: joints)
        case .pushup:
            return averageElbowAngle(from: joints)
        }
    }

    private func averageKneeAngle(from joints: [Joint]) -> CGFloat? {
        let lookup = Dictionary(uniqueKeysWithValues: joints.map { ($0.name, $0) })

        let left = angle(
            a: lookup[.leftHip]?.location,
            b: lookup[.leftKnee]?.location,
            c: lookup[.leftAnkle]?.location
        )
        let right = angle(
            a: lookup[.rightHip]?.location,
            b: lookup[.rightKnee]?.location,
            c: lookup[.rightAnkle]?.location
        )

        return average(of: [left, right])
    }

    private func averageElbowAngle(from joints: [Joint]) -> CGFloat? {
        let lookup = Dictionary(uniqueKeysWithValues: joints.map { ($0.name, $0) })

        let left = angle(
            a: lookup[.leftShoulder]?.location,
            b: lookup[.leftElbow]?.location,
            c: lookup[.leftWrist]?.location
        )
        let right = angle(
            a: lookup[.rightShoulder]?.location,
            b: lookup[.rightElbow]?.location,
            c: lookup[.rightWrist]?.location
        )

        return average(of: [left, right])
    }

    private func angle(a: CGPoint?, b: CGPoint?, c: CGPoint?) -> CGFloat? {
        guard let a, let b, let c else {
            return nil
        }

        let ab = CGPoint(x: a.x - b.x, y: a.y - b.y)
        let cb = CGPoint(x: c.x - b.x, y: c.y - b.y)

        let dot = (ab.x * cb.x) + (ab.y * cb.y)
        let abMagnitude = sqrt((ab.x * ab.x) + (ab.y * ab.y))
        let cbMagnitude = sqrt((cb.x * cb.x) + (cb.y * cb.y))

        guard abMagnitude > 0, cbMagnitude > 0 else {
            return nil
        }

        let cosine = max(-1, min(1, dot / (abMagnitude * cbMagnitude)))
        return acos(cosine) * (180 / .pi)
    }

    private func average(of values: [CGFloat?]) -> CGFloat? {
        let valid = values.compactMap { $0 }
        guard !valid.isEmpty else {
            return nil
        }

        let sum = valid.reduce(0, +)
        return sum / CGFloat(valid.count)
    }
}
