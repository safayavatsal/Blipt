import Foundation

/// Centralized dependency container for protocol-based service injection.
/// Provides shared singleton instances so ViewModels use the same data service (and its cache).
@Observable
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()

    let ocrService: OCRServiceProtocol
    let rtoDataService: RTODataService
    let selectedCountry: Country

    var parser: PlateParserProtocol {
        PlateParserFactory.parser(for: selectedCountry)
    }

    init(
        ocrService: OCRServiceProtocol = VisionOCRService(mode: .accurate),
        rtoDataService: RTODataService = RTODataService(),
        selectedCountry: Country = .india
    ) {
        self.ocrService = ocrService
        self.rtoDataService = rtoDataService
        self.selectedCountry = selectedCountry
    }

    /// Creates a container with mock services for SwiftUI previews and testing.
    static func mock() -> DependencyContainer {
        DependencyContainer(
            ocrService: MockOCRService.samplePlate(),
            rtoDataService: RTODataService(),
            selectedCountry: .india
        )
    }
}
