import AVFoundation
import Combine
import Foundation

final class PoseViewModel: ObservableObject {
    @Published private(set) var joints: [Joint] = []

    private let poseEstimator = PoseEstimator()
    private let poseQueue = DispatchQueue(label: "pose.estimation.queue", qos: .userInitiated)
    private let processingLock = NSLock()
    private var isProcessing = false

    func process(sampleBuffer: CMSampleBuffer, mirrored: Bool) {
        processingLock.lock()
        if isProcessing {
            processingLock.unlock()
            return
        }
        isProcessing = true
        processingLock.unlock()

        poseQueue.async { [weak self] in
            guard let self else { return }
            let detectedJoints = self.poseEstimator.detectJoints(in: sampleBuffer, mirrored: mirrored)

            DispatchQueue.main.async {
                self.joints = detectedJoints
                self.processingLock.lock()
                self.isProcessing = false
                self.processingLock.unlock()
            }
        }
    }
}
