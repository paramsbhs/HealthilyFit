import SwiftUI

struct PoseOverlayView: View {
    let joints: [Joint]

    init(joints: [Joint] = []) {
        self.joints = joints
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let lookup = Dictionary(uniqueKeysWithValues: joints.map { ($0.name, $0) })

                for (source, target) in skeletonConnections {
                    guard let sourceJoint = lookup[source], let targetJoint = lookup[target] else {
                        continue
                    }

                    let sourcePoint = sourceJoint.location.denormalized(in: geometry.size)
                    let targetPoint = targetJoint.location.denormalized(in: geometry.size)

                    var path = Path()
                    path.move(to: sourcePoint)
                    path.addLine(to: targetPoint)

                    let confidence = (sourceJoint.confidence + targetJoint.confidence) / 2
                    context.stroke(path, with: .color(color(for: confidence)), lineWidth: 3)
                }

                for joint in joints {
                    let point = joint.location.denormalized(in: geometry.size)
                    let markerRect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: markerRect), with: .color(color(for: joint.confidence)))
                }
            }
            .background(Color.clear)
        }
        .allowsHitTesting(false)
    }

    private func color(for confidence: CGFloat) -> Color {
        let clamped = max(0, min(confidence, 1))
        return Color(
            red: 1 - clamped,
            green: clamped,
            blue: 0.15
        )
    }
}

#Preview {
    ZStack {
        Color.black
        PoseOverlayView()
    }
}
