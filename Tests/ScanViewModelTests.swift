import XCTest
import CoreGraphics
@testable import Blipt

@MainActor
final class ScanViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeTestImage() -> CGImage {
        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return context.makeImage()!
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        let vm = ScanViewModel(ocrService: MockOCRService())
        XCTAssertEqual(vm.scanState, .idle)
    }

    // MARK: - Process Image

    func testProcessImageWithValidPlate() async {
        let mock = MockOCRService(mockResults: [
            OCRResult(text: "MH 12 AB 1234", confidence: 0.95, boundingBox: .zero)
        ])
        let vm = ScanViewModel(country: .india, ocrService: mock)
        await vm.loadDataIfNeeded()

        let image = makeTestImage()
        await vm.processImage(image)

        if case .result(let plate, _) = vm.scanState {
            XCTAssertEqual(plate.normalizedPlate, "MH 12 AB 1234")
            if case .indian(let state, let rto, let series, let number) = plate.components {
                XCTAssertEqual(state, "MH")
                XCTAssertEqual(rto, "12")
                XCTAssertEqual(series, "AB")
                XCTAssertEqual(number, "1234")
            } else {
                XCTFail("Expected indian components")
            }
        } else {
            XCTFail("Expected .result state, got \(vm.scanState)")
        }
    }

    func testProcessImageWithNoPlateShowsError() async {
        let mock = MockOCRService(mockResults: [
            OCRResult(text: "random text", confidence: 0.8, boundingBox: .zero)
        ])
        let vm = ScanViewModel(country: .india, ocrService: mock)
        await vm.loadDataIfNeeded()

        let image = makeTestImage()
        await vm.processImage(image)

        if case .error(let message) = vm.scanState {
            XCTAssertFalse(message.isEmpty, "Error message should not be empty")
        } else {
            XCTFail("Expected .error state, got \(vm.scanState)")
        }
    }

    // MARK: - Reset

    func testResetClearsState() async {
        let mock = MockOCRService(mockResults: [
            OCRResult(text: "MH 12 AB 1234", confidence: 0.95, boundingBox: .zero)
        ])
        let vm = ScanViewModel(country: .india, ocrService: mock)
        await vm.loadDataIfNeeded()

        let image = makeTestImage()
        await vm.processImage(image)

        // Verify we have a result first
        if case .result = vm.scanState {
            // good
        } else {
            XCTFail("Expected .result state before reset")
        }

        vm.reset()
        XCTAssertEqual(vm.scanState, .idle, "State should be idle after reset")
        XCTAssertNil(vm.selectedPhoto, "selectedPhoto should be nil after reset")
        XCTAssertNil(vm.capturedImage, "capturedImage should be nil after reset")
    }

    // MARK: - Switch Country

    func testSwitchCountryChangesParser() {
        let vm = ScanViewModel(country: .india, ocrService: MockOCRService())
        XCTAssertEqual(vm.country, .india)

        vm.switchCountry(.morocco)
        XCTAssertEqual(vm.country, .morocco)
    }
}
