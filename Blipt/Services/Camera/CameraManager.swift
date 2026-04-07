import AVFoundation
import SwiftUI

@Observable @MainActor
final class CameraManager: NSObject {
    enum Status {
        case unknown
        case authorized
        case denied
        case configuring
        case running
        case failed(String)
    }

    var status: Status = .unknown
    var isFlashOn = false

    nonisolated(unsafe) let session = AVCaptureSession()
    // videoOutput is only set from sessionQueue, read from MainActor
    private nonisolated(unsafe) var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.blipt.camera.session")
    private let delegateQueue = DispatchQueue(label: "com.blipt.camera.output", qos: .userInitiated)

    private weak var sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    func configure(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        sampleBufferDelegate = delegate
        checkPermission()
    }

    // MARK: - Permissions

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.status = .denied
                    }
                }
            }
        case .denied, .restricted:
            status = .denied
        @unknown default:
            status = .failed("Unknown camera authorization status")
        }
    }

    // MARK: - Session Setup

    private func setupSession() {
        status = .configuring
        let session = self.session
        let delegate = self.sampleBufferDelegate
        let delegateQueue = self.delegateQueue

        sessionQueue.async { [weak self] in
            session.beginConfiguration()
            session.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                Task { @MainActor in self?.status = .failed("Cannot access camera") }
                return
            }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

            if let delegate {
                output.setSampleBufferDelegate(delegate, queue: delegateQueue)
            }

            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                Task { @MainActor in self?.status = .failed("Cannot add video output") }
                return
            }
            session.addOutput(output)

            if let connection = output.connection(with: .video) {
                connection.videoRotationAngle = 90
            }

            self?.videoOutput = output
            session.commitConfiguration()

            Task { @MainActor in self?.status = .authorized }
        }
    }

    // MARK: - Start / Stop

    func start() {
        let session = self.session
        guard !session.isRunning else { return }
        sessionQueue.async { [weak self] in
            session.startRunning()
            Task { @MainActor in self?.status = .running }
        }
    }

    func stop() {
        let session = self.session
        guard session.isRunning else { return }
        sessionQueue.async {
            session.stopRunning()
        }
    }

    // MARK: - Flash / Torch

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        isFlashOn.toggle()

        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            isFlashOn = false
        }
    }
}
