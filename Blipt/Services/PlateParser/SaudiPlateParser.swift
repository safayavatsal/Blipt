import Foundation

/// Saudi Arabia plate format: [4 digits] [3 Arabic/Latin letters]
/// New format: NNNN LLL (e.g., 1234 ABC)
/// Letters use Arabic-Latin mapping: A=أ, B=ب, etc.
struct SaudiPlateParser: PlateParserProtocol {
    let country: Country = .saudiArabia

    // Pattern: 1-4 digits + 1-3 letters
    private static let pattern = #"^(\d{1,4})\s*([A-Z]{1,3})$"#
    // Reverse: letters first then digits
    private static let reversePattern = #"^([A-Z]{1,3})\s*(\d{1,4})$"#

    private static let regionFromLetter: [Character: String] = [
        "A": "Riyadh", "B": "Riyadh", "D": "Riyadh",
        "R": "Riyadh", "S": "Riyadh", "L": "Riyadh",
        "H": "Jeddah", "J": "Jeddah", "K": "Jeddah",
        "T": "Makkah", "U": "Makkah",
        "E": "Dammam", "N": "Dammam",
    ]

    func parse(ocrText: String) -> PlateParseResult? {
        let normalized = PlateNormalizer.normalize(ocrText)
        guard normalized.count >= 4 else { return nil }

        // Try digits-first pattern
        if let result = tryPattern(Self.pattern, text: normalized, digitsGroup: 1, lettersGroup: 2) {
            return result
        }

        // Try letters-first pattern
        if let result = tryPattern(Self.reversePattern, text: normalized, digitsGroup: 2, lettersGroup: 1) {
            return result
        }

        return nil
    }

    private func tryPattern(_ pattern: String, text: String, digitsGroup: Int, lettersGroup: Int) -> PlateParseResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 3,
              let digitsRange = Range(match.range(at: digitsGroup), in: text),
              let lettersRange = Range(match.range(at: lettersGroup), in: text) else {
            return nil
        }

        let number = String(text[digitsRange])
        let sequence = String(text[lettersRange])

        // Determine region from first letter
        let region = Self.regionFromLetter[sequence.first ?? "?"] ?? "Unknown"

        return PlateParseResult(
            rawText: text,
            normalizedPlate: "\(number) \(sequence)",
            components: .saudi(region: region, sequence: sequence, number: number),
            confidence: 0.75,
            format: .saudi
        )
    }

    func validate(plate: String) -> Bool {
        parse(ocrText: plate) != nil
    }
}
