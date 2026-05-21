import CoreGraphics
import Foundation

struct FormAnalysis {
    let feedbackMessages: [String]
    let score: Double
}

final class FormAnalyzer {
    func analyze(exercise: ExerciseType, joints: [Joint]) -> FormAnalysis {
        switch exercise {
        case .squat:
            return analyzeSquat(joints: joints)
        case .pushup:
            return analyzePushup(joints: joints)
        }
    }

    private func analyzeSquat(joints: [Joint]) -> FormAnalysis {
        let lookup = Dictionary(uniqueKeysWithValues: joints.map { ($0.name, $0) })

        guard !lookup.isEmpty else {
            return FormAnalysis(feedbackMessages: ["Step into frame"], score: 0)
        }

        var checks: [Bool] = []
        var messages: [String] = []

        if let kneeAngle = averageAngle(
            angle(a: lookup[.leftHip]?.location, b: lookup[.leftKnee]?.location, c: lookup[.leftAnkle]?.location),
            angle(a: lookup[.rightHip]?.location, b: lookup[.rightKnee]?.location, c: lookup[.rightAnkle]?.location)
        ) {
            let depthGood = kneeAngle < 100
            checks.append(depthGood)
            messages.append(depthGood ? "Depth good ✓" : "Go deeper")
        }

        if let kneeTracking = kneeTrackingScore(lookup: lookup) {
            let trackingGood = kneeTracking > 0.65
            checks.append(trackingGood)
            messages.append(trackingGood ? "Knees tracking good" : "Knees out")
        }

        if let torsoTilt = torsoTiltDegrees(lookup: lookup) {
            let backGood = torsoTilt < 25
            checks.append(backGood)
            messages.append(backGood ? "Back straight ✓" : "Keep chest up")
        }

        return buildAnalysis(messages: messages, checks: checks)
    }

    private func analyzePushup(joints: [Joint]) -> FormAnalysis {
        let lookup = Dictionary(uniqueKeysWithValues: joints.map { ($0.name, $0) })

        guard !lookup.isEmpty else {
            return FormAnalysis(feedbackMessages: ["Step into frame"], score: 0)
        }

        var checks: [Bool] = []
        var messages: [String] = []

        if let elbowAngle = averageAngle(
            angle(a: lookup[.leftShoulder]?.location, b: lookup[.leftElbow]?.location, c: lookup[.leftWrist]?.location),
            angle(a: lookup[.rightShoulder]?.location, b: lookup[.rightElbow]?.location, c: lookup[.rightWrist]?.location)
        ) {
            let depthGood = elbowAngle < 95
            checks.append(depthGood)
            messages.append(depthGood ? "Depth good ✓" : "Lower chest more")
        }

        if let plankLine = bodyLineScore(lookup: lookup) {
            let plankGood = plankLine > 0.72
            checks.append(plankGood)
            messages.append(plankGood ? "Back straight ✓" : "Keep hips level")
        }

        if let shoulderStable = shoulderStability(lookup: lookup) {
            let stable = shoulderStable > 0.72
            checks.append(stable)
            messages.append(stable ? "Shoulders stable ✓" : "Control descent")
        }

        return buildAnalysis(messages: messages, checks: checks)
    }

    private func buildAnalysis(messages: [String], checks: [Bool]) -> FormAnalysis {
        guard !checks.isEmpty else {
            return FormAnalysis(feedbackMessages: ["Finding body landmarks..."], score: 0)
        }

        let passed = checks.filter { $0 }.count
        let score = Double(passed) / Double(checks.count)
        return FormAnalysis(feedbackMessages: messages, score: score)
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

    private func averageAngle(_ lhs: CGFloat?, _ rhs: CGFloat?) -> CGFloat? {
        let values = [lhs, rhs].compactMap { $0 }
        guard !values.isEmpty else {
            return nil
        }
        return values.reduce(0, +) / CGFloat(values.count)
    }

    private func torsoTiltDegrees(lookup: [JointName: Joint]) -> CGFloat? {
        guard let leftShoulder = lookup[.leftShoulder]?.location,
              let rightShoulder = lookup[.rightShoulder]?.location,
              let leftHip = lookup[.leftHip]?.location,
              let rightHip = lookup[.rightHip]?.location else {
            return nil
        }

        let shoulderMid = CGPoint(x: (leftShoulder.x + rightShoulder.x) / 2, y: (leftShoulder.y + rightShoulder.y) / 2)
        let hipMid = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)

        let dx = shoulderMid.x - hipMid.x
        let dy = shoulderMid.y - hipMid.y
        guard dy != 0 else {
            return 90
        }

        return abs(atan(dx / dy)) * (180 / .pi)
    }

    private func kneeTrackingScore(lookup: [JointName: Joint]) -> CGFloat? {
        guard let leftKnee = lookup[.leftKnee]?.location,
              let leftAnkle = lookup[.leftAnkle]?.location,
              let rightKnee = lookup[.rightKnee]?.location,
              let rightAnkle = lookup[.rightAnkle]?.location else {
            return nil
        }

        let leftOffset = abs(leftKnee.x - leftAnkle.x)
        let rightOffset = abs(rightKnee.x - rightAnkle.x)
        let averageOffset = (leftOffset + rightOffset) / 2
        let normalized = max(0, min(1, 1 - (averageOffset / 0.16)))
        return normalized
    }

    private func bodyLineScore(lookup: [JointName: Joint]) -> CGFloat? {
        let left = angle(a: lookup[.leftShoulder]?.location, b: lookup[.leftHip]?.location, c: lookup[.leftAnkle]?.location)
        let right = angle(a: lookup[.rightShoulder]?.location, b: lookup[.rightHip]?.location, c: lookup[.rightAnkle]?.location)
        guard let average = averageAngle(left, right) else {
            return nil
        }

        let deviation = abs(180 - average)
        return max(0, min(1, 1 - (deviation / 45)))
    }

    private func shoulderStability(lookup: [JointName: Joint]) -> CGFloat? {
        guard let leftShoulder = lookup[.leftShoulder]?.location,
              let rightShoulder = lookup[.rightShoulder]?.location,
              let leftElbow = lookup[.leftElbow]?.location,
              let rightElbow = lookup[.rightElbow]?.location else {
            return nil
        }

        let leftDrop = abs(leftShoulder.y - leftElbow.y)
        let rightDrop = abs(rightShoulder.y - rightElbow.y)
        let imbalance = abs(leftDrop - rightDrop)
        return max(0, min(1, 1 - (imbalance / 0.25)))
    }
}
