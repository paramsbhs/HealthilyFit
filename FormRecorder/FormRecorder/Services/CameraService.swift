import AVFoundation
import Combine
import Foundation

final class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var isSessionRunning = false
    @Published private(set) var isUsingFrontCamera = true
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue", qos: .userInitiated)
    private let sampleBufferHandlerLock = NSLock()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false
    private var sampleBufferHandler: ((CMSampleBuffer, Bool) -> Void)?

    override init() {
        super.init()
    }

    func requestAccessIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.authorizationStatus = .authorized
            }
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.authorizationStatus = granted ? .authorized : .denied
                    if !granted {
                        self.errorMessage = "Camera access is required to record workouts."
                    } else {
                        self.errorMessage = nil
                    }
                }
                if granted {
                    self?.startSession()
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                self.errorMessage = "Enable camera access in Settings to use live recording."
            }
        @unknown default:
            DispatchQueue.main.async {
                self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                self.errorMessage = "Unknown camera authorization state."
            }
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
                DispatchQueue.main.async {
                    self.errorMessage = "Camera permission not granted."
                }
                return
            }

            if !self.isConfigured {
                self.configureSession()
            }

            guard self.isConfigured else { return }

            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }

            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }

    func setSampleBufferHandler(_ handler: ((CMSampleBuffer, Bool) -> Void)?) {
        sampleBufferHandlerLock.lock()
        sampleBufferHandler = handler
        sampleBufferHandlerLock.unlock()
    }

    private func configureSession() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.errorMessage = "Camera preview is unavailable in iOS Simulator. Run on a physical iPhone."
        }
        isConfigured = false
        #endif
        #if !targetEnvironment(simulator)
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async {
                self.errorMessage = "No camera available on this device."
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            if session.canAddInput(input) {
                session.addInput(input)
                DispatchQueue.main.async {
                    self.isUsingFrontCamera = camera.position == .front
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to attach camera input."
                }
                return
            }

            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                if let connection = videoOutput.connection(with: .video), connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = camera.position == .front
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to attach camera output."
                }
                return
            }

            isConfigured = true
            DispatchQueue.main.async {
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to configure camera: \(error.localizedDescription)"
            }
        }
        #endif
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        sampleBufferHandlerLock.lock()
        let handler = sampleBufferHandler
        sampleBufferHandlerLock.unlock()
        handler?(sampleBuffer, connection.isVideoMirrored)
    }
}
