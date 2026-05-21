import AVFoundation
import CoreData
import SwiftUI
import UIKit

struct RecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var cameraService = CameraService()
    @StateObject private var poseViewModel = PoseViewModel()
    @StateObject private var repCounterViewModel = RepCounterViewModel(targetReps: 12)
    @StateObject private var formViewModel = FormViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var saveStatusMessage: String?

    var body: some View {
        ZStack {
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()

            PoseOverlayView(joints: poseViewModel.joints)
                .ignoresSafeArea()

            VStack {
                VStack(spacing: 10) {
                    RepCounterView(viewModel: repCounterViewModel)
                    FormFeedbackView(viewModel: formViewModel)
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)

                Spacer()

                VStack(spacing: 12) {
                    Picker("Exercise", selection: $repCounterViewModel.selectedExercise) {
                        ForEach(ExerciseType.allCases) { exercise in
                            Text(exercise.displayName).tag(exercise)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(repCounterViewModel.isTracking)

                    Button {
                        if repCounterViewModel.isTracking {
                            repCounterViewModel.stopSet()
                        } else {
                            repCounterViewModel.startSet()
                        }
                    } label: {
                        Text(repCounterViewModel.isTracking ? "Stop Set" : "Start Set")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(repCounterViewModel.isTracking ? Color.red : Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        workoutViewModel.saveWorkout(
                            exerciseType: repCounterViewModel.selectedExercise,
                            reps: repCounterViewModel.repCount,
                            targetReps: repCounterViewModel.targetReps,
                            formScore: formViewModel.formScore
                        )
                        saveStatusMessage = "Workout saved"
                    } label: {
                        Text("Save Workout")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(repCounterViewModel.isTracking || repCounterViewModel.repCount == 0)

                    if let saveStatusMessage {
                        Text(saveStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }

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
            workoutViewModel.setContext(viewContext)
            cameraService.setSampleBufferHandler { sampleBuffer, mirrored in
                poseViewModel.process(sampleBuffer: sampleBuffer, mirrored: mirrored)
            }
            cameraService.requestAccessIfNeeded()
        }
        .onChange(of: poseViewModel.joints) { _, joints in
            repCounterViewModel.process(joints: joints)
            formViewModel.process(
                joints: joints,
                exercise: repCounterViewModel.selectedExercise,
                isTracking: repCounterViewModel.isTracking
            )
        }
        .onChange(of: repCounterViewModel.selectedExercise) { _, exercise in
            repCounterViewModel.selectExercise(exercise)
            formViewModel.setExercise(exercise)
            saveStatusMessage = nil
        }
        .onChange(of: repCounterViewModel.isTracking) { _, isTracking in
            if isTracking {
                formViewModel.startSet(exercise: repCounterViewModel.selectedExercise)
                saveStatusMessage = nil
            } else {
                formViewModel.stopSet()
            }
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
