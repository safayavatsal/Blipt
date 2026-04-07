import CoreImage
import CoreMedia

final class MockOCRService: OCRServiceProtocol, @unchecked Sendable {
    let mockResults: [OCRResult]

    init(mockResults: [OCRResult] = []) {
        self.mockResults = mockResults
    }

    func recognizeText(in image: CGImage, regionOfInterest: CGRect?) async throws -> [OCRResult] {
        mockResults
    }

    func recognizeText(from sampleBuffer: CMSampleBuffer) async throws -> [OCRResult] {
        mockResults
    }

    static func samplePlate() -> MockOCRService {
        MockOCRService(mockResults: [
            OCRResult(text: "MH 12 AB 1234", confidence: 0.95, boundingBox: .init(x: 0.2, y: 0.3, width: 0.6, height: 0.1))
        ])
    }
}
