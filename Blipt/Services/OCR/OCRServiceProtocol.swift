import CoreImage
import CoreMedia

struct OCRResult: Equatable {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

protocol OCRServiceProtocol: Sendable {
    func recognizeText(in image: CGImage, regionOfInterest: CGRect?) async throws -> [OCRResult]
    func recognizeText(from sampleBuffer: CMSampleBuffer) async throws -> [OCRResult]
}

extension OCRServiceProtocol {
    func recognizeText(in image: CGImage) async throws -> [OCRResult] {
        try await recognizeText(in: image, regionOfInterest: nil)
    }
}
