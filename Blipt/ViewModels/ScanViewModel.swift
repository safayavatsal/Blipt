import SwiftUI
import PhotosUI

enum ScanState: Equatable {
    case idle
    case processing
    case result(PlateParseResult, LocationInfo?)
    case error(String)
}

enum ScanMode {
    case camera
    case photo
}

@Observable @MainActor
final class ScanViewModel {
    var scanState: ScanState = .idle
    var selectedPhoto: PhotosPickerItem?
    var capturedImage: UIImage?
    var scanMode: ScanMode = .camera

    // Camera
    let cameraManager = CameraManager()
    private(set) var plateDetector: PlateDetector

    private let ocrService: OCRServiceProtocol
    private var parser: PlateParserProtocol
    private var dataService: CountryDataServiceProtocol

    // Country-specific services
    private let indianDataService = RTODataService()
    private let moroccoDataService = MoroccoDataService()

    // History
    var historyStore = ScanHistoryStore()

    private(set) var country: Country

    init(
        country: Country = .india,
        ocrService: OCRServiceProtocol = VisionOCRService(mode: .accurate)
    ) {
        self.country = country
        self.ocrService = ocrService
        self.parser = PlateParserFactory.parser(for: country)
        self.dataService = RTODataService() // placeholder, set properly below
        self.plateDetector = PlateDetector(parser: PlateParserFactory.parser(for: country))

        // Set correct data service
        switch country {
        case .india: self.dataService = indianDataService
        case .morocco: self.dataService = moroccoDataService
        }
    }

    func switchCountry(_ newCountry: Country) {
        guard newCountry != country else { return }
        country = newCountry
        parser = PlateParserFactory.parser(for: newCountry)
        plateDetector = PlateDetector(parser: parser)

        switch newCountry {
        case .india: dataService = indianDataService
        case .morocco: dataService = moroccoDataService
        }

        reset()
        Task { await loadDataIfNeeded() }
    }

    func loadDataIfNeeded() async {
        try? await dataService.loadData()
    }

    // MARK: - Camera Flow

    func startCamera() {
        scanMode = .camera
        plateDetector.reset()
        cameraManager.configure(delegate: plateDetector)
        cameraManager.start()
    }

    func stopCamera() {
        cameraManager.stop()
    }

    func confirmDetection() {
        guard let detection = plateDetector.currentDetection else { return }
        let location = dataService.lookup(plate: detection.parseResult)
        scanState = .result(detection.parseResult, location)
        saveToHistory(plate: detection.parseResult, location: location)
    }

    func manualCapture() {
        if let detection = plateDetector.currentDetection {
            let location = dataService.lookup(plate: detection.parseResult)
            scanState = .result(detection.parseResult, location)
            saveToHistory(plate: detection.parseResult, location: location)
        } else {
            scanState = .error("No plate detected. Try holding the camera steady.")
        }
    }

    // MARK: - Photo Flow

    func processSelectedPhoto() async {
        guard let selectedPhoto else { return }

        scanState = .processing

        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else {
                scanState = .error("Could not load image")
                return
            }

            capturedImage = uiImage
            await processImage(cgImage)
        } catch {
            scanState = .error("Failed to load photo: \(error.localizedDescription)")
        }
    }

    private let preprocessor = ImagePreprocessor()

    func processImage(_ cgImage: CGImage) async {
        scanState = .processing

        do {
            // Try raw image first
            let ocrResults = try await ocrService.recognizeText(in: cgImage)

            for ocrResult in ocrResults {
                if let parseResult = parser.parse(ocrText: ocrResult.text) {
                    let location = dataService.lookup(plate: parseResult)
                    scanState = .result(parseResult, location)
                    saveToHistory(plate: parseResult, location: location)
                    return
                }
            }

            let allText = ocrResults.map(\.text).joined(separator: " ")
            if let parseResult = parser.parse(ocrText: allText) {
                let location = dataService.lookup(plate: parseResult)
                scanState = .result(parseResult, location)
                saveToHistory(plate: parseResult, location: location)
                return
            }

            // Retry with preprocessed image (crop, contrast, sharpen)
            let enhanced = await preprocessor.preprocess(cgImage)
            let retryResults = try await ocrService.recognizeText(in: enhanced)

            for ocrResult in retryResults {
                if let parseResult = parser.parse(ocrText: ocrResult.text) {
                    let location = dataService.lookup(plate: parseResult)
                    scanState = .result(parseResult, location)
                    saveToHistory(plate: parseResult, location: location)
                    return
                }
            }

            let retryAllText = retryResults.map(\.text).joined(separator: " ")
            if let parseResult = parser.parse(ocrText: retryAllText) {
                let location = dataService.lookup(plate: parseResult)
                scanState = .result(parseResult, location)
                saveToHistory(plate: parseResult, location: location)
                return
            }

            scanState = .error("No license plate detected in the image")
        } catch {
            scanState = .error("OCR failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset

    func reset() {
        scanState = .idle
        selectedPhoto = nil
        capturedImage = nil
        plateDetector.reset()
    }

    func resumeCamera() {
        reset()
        startCamera()
    }

    // MARK: - History

    private func saveToHistory(plate: PlateParseResult, location: LocationInfo?) {
        let item = ScanHistoryItem(
            plate: plate.rawText,
            normalizedPlate: plate.normalizedPlate,
            stateName: location?.stateName,
            stateCode: location?.stateCode,
            districtName: location?.districtName,
            rtoName: location?.rtoName,
            country: country.rawValue,
            format: plate.format.rawValue,
            confidence: plate.confidence
        )
        historyStore.add(item)
    }
}
