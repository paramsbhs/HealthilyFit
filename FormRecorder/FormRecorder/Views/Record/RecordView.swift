import AVFoundation
import SwiftUI
import UIKit

struct RecordView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var poseViewModel = PoseViewModel()

    var body: some View {
        ZStack {
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()

            PoseOverlayView(joints: poseViewModel.joints)
                .ignoresSafeArea()

            if let errorMessage = cameraService.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            } else if !cameraService.isSessionRunning {
                VStack {
                    Spacer()
                    Text("Starting camera...")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 20)
                }
            }
        }
        .background(Color.black)
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cameraService.setSampleBufferHandler { sampleBuffer, mirrored in
                poseViewModel.process(sampleBuffer: sampleBuffer, mirrored: mirrored)
            }
            cameraService.requestAccessIfNeeded()
        }
        .onDisappear {
            cameraService.setSampleBufferHandler(nil)
            cameraService.stopSession()
        }
    }
}
    
private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.videoPreviewLayer.session !== session {
            uiView.videoPreviewLayer.session = session
        }
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Layer must be AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}

#Preview {
    RecordView()
}
