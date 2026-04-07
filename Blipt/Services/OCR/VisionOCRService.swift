import Vision
import CoreImage
import CoreMedia

final class VisionOCRService: OCRServiceProtocol {
    enum RecognitionMode {
        case accurate
        case fast
    }

    private let mode: RecognitionMode

    init(mode: RecognitionMode = .accurate) {
        self.mode = mode
    }

    func recognizeText(in image: CGImage, regionOfInterest: CGRect? = nil) async throws -> [OCRResult] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = observations.compactMap { observation -> OCRResult? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return OCRResult(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                .sorted { $0.confidence > $1.confidence }

                continuation.resume(returning: results)
            }

            request.recognitionLevel = mode == .accurate ? .accurate : .fast
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]

            if let roi = regionOfInterest {
                request.regionOfInterest = roi
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func recognizeText(from sampleBuffer: CMSampleBuffer) async throws -> [OCRResult] {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = observations.compactMap { observation -> OCRResult? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return OCRResult(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                .sorted { $0.confidence > $1.confidence }

                continuation.resume(returning: results)
            }

            request.recognitionLevel = mode == .accurate ? .accurate : .fast
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
