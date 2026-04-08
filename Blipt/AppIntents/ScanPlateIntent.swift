import AppIntents

struct ScanPlateIntent: AppIntent {
    static let title: LocalizedStringResource = "Scan a License Plate"
    static let description: IntentDescription = "Open Blipt's camera to scan a license plate."
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct LookUpPlateIntent: AppIntent {
    static let title: LocalizedStringResource = "Look Up a Plate"
    static let description: IntentDescription = "Look up a license plate number to find its registered location."
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Plate Number")
    var plateNumber: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let parser = IndianPlateParser()
        guard let parseResult = parser.parse(ocrText: plateNumber) else {
            return .result(value: "Could not parse plate: \(plateNumber)")
        }

        let dataService = await MainActor.run { RTODataService() }
        try? await dataService.loadData()
        let location = await MainActor.run { dataService.lookup(plate: parseResult) }

        if let loc = location {
            return .result(value: "\(parseResult.normalizedPlate): \(loc.stateName), \(loc.districtName) — \(loc.rtoName)")
        }

        return .result(value: "\(parseResult.normalizedPlate): Location not found")
    }
}

// MARK: - Shortcuts Provider

struct BliptShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanPlateIntent(),
            phrases: [
                "Scan a plate with \(.applicationName)",
                "Open \(.applicationName) camera",
                "Scan license plate in \(.applicationName)"
            ],
            shortTitle: "Scan Plate",
            systemImageName: "camera.viewfinder"
        )
    }
}
