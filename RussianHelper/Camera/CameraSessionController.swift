@preconcurrency import AVFoundation
import CoreGraphics
@preconcurrency import CoreMedia
import Foundation
import QuartzCore

final class CameraSessionController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onDetections: (([DetectedTextRegion], CGFloat) -> Void)?

    private let session: AVCaptureSession
    private let output = AVCaptureVideoDataOutput()
    private let outputQueue = DispatchQueue(label: "RussianHelper.camera.frames", qos: .userInitiated)
    private let recognizer = RussianTextRecognizer()

    private var isProcessing = false
    private var lastRecognitionTime: CFTimeInterval = 0
    private var frameID = 0

    init(session: AVCaptureSession) {
        self.session = session
    }

    func configure() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
        else {
            throw CameraError.missingCamera
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        output.setSampleBufferDelegate(self, queue: outputQueue)

        guard session.canAddOutput(output) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)

        if let connection = output.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    func start() {
        guard !session.isRunning else { return }
        outputQueue.async { [session] in
            session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        outputQueue.async { [session] in
            session.stopRunning()
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CACurrentMediaTime()
        guard !isProcessing, now - lastRecognitionTime >= 0.30 else { return }

        isProcessing = true
        lastRecognitionTime = now
        frameID += 1

        let currentFrameID = frameID
        let aspectRatio = Self.aspectRatio(from: sampleBuffer)

        Task(priority: .userInitiated) { [recognizer, weak self] in
            let regions = await recognizer.recognize(sampleBuffer: sampleBuffer, frameID: currentFrameID)
            self?.onDetections?(regions, aspectRatio)
            self?.outputQueue.async {
                self?.isProcessing = false
            }
        }
    }

    private static func aspectRatio(from sampleBuffer: CMSampleBuffer) -> CGFloat {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return 3.0 / 4.0
        }
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        guard width > 0, height > 0 else { return 3.0 / 4.0 }
        return width / height
    }

    enum CameraError: Error {
        case missingCamera
        case cannotAddInput
        case cannotAddOutput
    }
}
