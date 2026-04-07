import AVFoundation
import Vision
import CoreImage

@Observable @MainActor
final class PlateDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    struct Detection: Equatable, Sendable {
        let text: String
        let parseResult: PlateParseResult
        let boundingBox: CGRect
        let confidence: Float
    }

    var currentDetection: Detection?
    var isConfirmed = false

    private nonisolated(unsafe) let parser: PlateParserProtocol
    private let confirmationThreshold: Int
    private let processEveryNthFrame: Int

    private nonisolated(unsafe) var frameCount = 0
    private nonisolated(unsafe) var _isProcessing = false

    // Debounce: require N consistent reads of the same plate
    private var consecutiveMatches: [String] = []

    // Smoothed bounding box (exponential moving average)
    private var smoothedBox: CGRect?
    private let smoothingFactor: CGFloat = 0.3

    init(
        parser: PlateParserProtocol = IndianPlateParser(),
        fps: Int = AppConstants.Limits.liveDetectionFPS,
        confirmationCount: Int = AppConstants.Limits.plateConfirmationCount
    ) {
        self.parser = parser
        self.confirmationThreshold = confirmationCount
        self.processEveryNthFrame = max(1, 30 / fps)
        super.init()
    }

    func reset() {
        currentDetection = nil
        isConfirmed = false
        consecutiveMatches = []
        smoothedBox = nil
        frameCount = 0
        _isProcessing = false
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1
        guard frameCount % processEveryNthFrame == 0 else { return }
        guard !_isProcessing else { return }

        _isProcessing = true

        // Extract pixel buffer synchronously on the callback queue
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            _isProcessing = false
            return
        }

        // Run OCR synchronously via Vision
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            _isProcessing = false
            return
        }

        guard let observations = request.results else {
            _isProcessing = false
            return
        }

        let ocrResults: [(String, Float, CGRect)] = observations.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            return (candidate.string, candidate.confidence, obs.boundingBox)
        }.sorted { $0.1 > $1.1 }

        // Parse on this queue (parser is a struct / pure function)
        var matchedResult: Detection?
        for (text, confidence, box) in ocrResults {
            if let parseResult = parser.parse(ocrText: text) {
                matchedResult = Detection(text: text, parseResult: parseResult, boundingBox: box, confidence: confidence)
                break
            }
        }

        let detection = matchedResult

        // Send results to main actor
        Task { @MainActor [weak self] in
            guard let self else { return }
            self._isProcessing = false

            guard !self.isConfirmed else { return }
            guard let detection else { return }

            self.applyDetection(detection)
        }
    }

    // MARK: - Apply Detection (MainActor)

    private func applyDetection(_ detection: Detection) {
        let smoothed = smoothBoundingBox(detection.boundingBox)

        currentDetection = Detection(
            text: detection.text,
            parseResult: detection.parseResult,
            boundingBox: smoothed,
            confidence: detection.confidence
        )

        let normalized = detection.parseResult.normalizedPlate
        consecutiveMatches.append(normalized)

        if consecutiveMatches.count > confirmationThreshold * 2 {
            consecutiveMatches = Array(consecutiveMatches.suffix(confirmationThreshold * 2))
        }

        if consecutiveMatches.count >= confirmationThreshold {
            let recent = consecutiveMatches.suffix(confirmationThreshold)
            if Set(recent).count == 1 {
                isConfirmed = true
            }
        }
    }

    // MARK: - Bounding Box Smoothing

    private func smoothBoundingBox(_ newBox: CGRect) -> CGRect {
        guard let prev = smoothedBox else {
            smoothedBox = newBox
            return newBox
        }

        let a = smoothingFactor
        let smoothed = CGRect(
            x: prev.origin.x * (1 - a) + newBox.origin.x * a,
            y: prev.origin.y * (1 - a) + newBox.origin.y * a,
            width: prev.width * (1 - a) + newBox.width * a,
            height: prev.height * (1 - a) + newBox.height * a
        )

        smoothedBox = smoothed
        return smoothed
    }
}
