import AVFoundation
import SwiftUI
import UIKit
import VisionKit

struct ScanFlowView: View {
    enum Stage: Equatable {
        case permission
        case scanner
        case denied
        case scannerError
        case review
    }

    @Environment(\.scenePhase) private var scenePhase

    let onCancel: () -> Void
    let onSaved: () -> Void

    @State private var stage: Stage = .permission
    @State private var capturedImage: UIImage?
    @State private var capturedAt = Date.now

    var body: some View {
        Group {
            switch stage {
            case .permission:
                CameraPermissionIntroView(
                    onClose: onCancel,
                    onContinue: continueFromPermission
                )
            case .scanner:
                scanner
            case .denied:
                CameraDeniedView(onClose: onCancel)
            case .scannerError:
                CameraScannerErrorView(
                    onRetry: retryScanner,
                    onBack: onCancel
                )
            case .review:
                if let capturedImage {
                    NewDocumentView(
                        image: capturedImage,
                        capturedAt: capturedAt,
                        onClose: onCancel,
                        onRetake: retake,
                        onSaved: onSaved
                    )
                } else {
                    CameraPermissionIntroView(
                        onClose: onCancel,
                        onContinue: continueFromPermission
                    )
                }
            }
        }
        .onAppear(perform: resolveInitialStage)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            if stage == .denied || stage == .scannerError {
                resolveInitialStage()
            }
        }
    }

    @ViewBuilder
    private var scanner: some View {
#if targetEnvironment(simulator)
        Color.black
            .ignoresSafeArea()
            .onAppear {
                capturedImage = SimulatorDocumentCapture.makeImage()
                capturedAt = .now
                stage = .review
            }
#else
        if VNDocumentCameraViewController.isSupported {
            DocumentScannerView(
                onScan: { image in
                    capturedImage = image
                    capturedAt = .now
                    stage = .review
                },
                onCancel: onCancel,
                onError: { stage = .scannerError }
            )
            .ignoresSafeArea()
        } else {
            CameraScannerErrorView(
                onRetry: retryScanner,
                onBack: onCancel
            )
        }
#endif
    }

    private func resolveInitialStage() {
#if targetEnvironment(simulator)
        if capturedImage == nil {
            stage = .permission
        }
#else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            stage = .scanner
        case .denied, .restricted:
            stage = .denied
        case .notDetermined:
            stage = .permission
        @unknown default:
            stage = .permission
        }
#endif
    }

    private func continueFromPermission() {
#if targetEnvironment(simulator)
        capturedImage = SimulatorDocumentCapture.makeImage()
        capturedAt = .now
        stage = .review
#else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            stage = .scanner
        case .denied, .restricted:
            stage = .denied
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    stage = granted ? .scanner : .denied
                }
            }
        @unknown default:
            stage = .denied
        }
#endif
    }

    private func retryScanner() {
#if targetEnvironment(simulator)
        capturedImage = SimulatorDocumentCapture.makeImage()
        capturedAt = .now
        stage = .review
#else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            stage = .scanner
        case .denied, .restricted:
            stage = .denied
        case .notDetermined:
            stage = .permission
        @unknown default:
            stage = .scannerError
        }
#endif
    }

    private func retake() {
#if targetEnvironment(simulator)
        capturedImage = SimulatorDocumentCapture.makeImage()
        capturedAt = .now
        stage = .review
#else
        stage = .scanner
#endif
    }
}
