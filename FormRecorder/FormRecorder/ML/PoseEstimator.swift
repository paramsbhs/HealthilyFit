import AVFoundation
import CoreGraphics
import Vision

final class PoseEstimator {
    private let request: VNDetectHumanBodyPoseRequest

    init() {
        self.request = VNDetectHumanBodyPoseRequest()
    }

    func detectJoints(in sampleBuffer: CMSampleBuffer, mirrored: Bool) -> [Joint] {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return []
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let observation = request.results?.first,
              let recognizedPoints = try? observation.recognizedPoints(.all) else {
            return []
        }

        return JointName.allCases.compactMap { jointName in
            guard let point = recognizedPoints[jointName.visionName], point.confidence > 0 else {
                return nil
            }

            var x = CGFloat(point.location.x)
            let y = 1 - CGFloat(point.location.y)

            if mirrored {
                x = 1 - x
            }

            return Joint(name: jointName, location: CGPoint(x: x, y: y), confidence: CGFloat(point.confidence))
        }
    }
}
