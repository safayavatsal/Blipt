import Foundation

/// UAE plate format: [Emirate Code] [Category Letter] [Number]
/// E.g., "Dubai A 12345", "Abu Dhabi 1 54321"
/// Emirate codes: Abu Dhabi(1-17), Dubai(A-Z), Sharjah(1-3), Ajman(A-D), UAQ(1-2), RAK(1-3), Fujairah(1-2)
struct UAEPlateParser: PlateParserProtocol {
    let country: Country = .uae

    private static let emirateCodes: [String: String] = [
        "AD": "Abu Dhabi", "AUH": "Abu Dhabi",
        "DXB": "Dubai", "DUBAI": "Dubai",
        "SHJ": "Sharjah", "SHARJAH": "Sharjah",
        "AJM": "Ajman", "AJMAN": "Ajman",
        "UAQ": "Umm Al Quwain",
        "RAK": "Ras Al Khaimah",
        "FUJ": "Fujairah", "FUJAIRAH": "Fujairah",
    ]

    // Pattern: optional emirate prefix + category letter(s) + number
    private static let pattern = #"^([A-Z]{1,7})?\s*([A-Z])\s*(\d{1,5})$"#

    func parse(ocrText: String) -> PlateParseResult? {
        let normalized = PlateNormalizer.normalize(ocrText)
        guard normalized.count >= 2 else { return nil }

        // Try regex match
        guard let regex = try? NSRegularExpression(pattern: Self.pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) else {
            return nil
        }

        let category: String
        let number: String
        var emirate = "Unknown"

        if match.numberOfRanges >= 4,
           let catRange = Range(match.range(at: 2), in: normalized),
           let numRange = Range(match.range(at: 3), in: normalized) {
            category = String(normalized[catRange])
            number = String(normalized[numRange])

            if let emRange = Range(match.range(at: 1), in: normalized) {
                let prefix = String(normalized[emRange])
                emirate = Self.emirateCodes[prefix] ?? prefix
            }
        } else {
            return nil
        }

        return PlateParseResult(
            rawText: ocrText,
            normalizedPlate: "\(emirate) \(category) \(number)",
            components: .uae(emirate: emirate, category: category, number: number),
            confidence: 0.8,
            format: .uae
        )
    }

    func validate(plate: String) -> Bool {
        parse(ocrText: plate) != nil
    }
}
