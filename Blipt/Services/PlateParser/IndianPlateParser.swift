import Foundation

struct IndianPlateParser: PlateParserProtocol {
    let country: Country = .india

    // Standard format: MH12AB1234 (after normalization)
    // State(2 letters) + RTO(2 digits) + Series(1-3 letters, no O or I) + Number(1-4 digits)
    private static let standardPattern = #"^([A-Z]{2})(\d{2})([A-HJ-NP-Z]{1,3})(\d{1,4})$"#

    // BH Series: 22BH0123C (after normalization)
    // Year(2 digits) + BH + Number(4 digits) + Category(1-2 letters)
    private static let bhSeriesPattern = #"^(\d{2})(BH)(\d{4})([A-HJ-NP-Z]{1,2})$"#

    // Loose standard pattern allowing OCR-confused characters
    private static let looseStandardPattern = #"^([A-Z0-9]{2})([0-9OILB]{2})([A-Z0-9]{1,3})([0-9OILB]{1,4})$"#

    static let validStateCodes: Set<String> = [
        "AN", "AP", "AR", "AS", "BR", "CG", "CH", "DD",
        "DL", "GA", "GJ", "HP", "HR", "JH", "JK", "KA",
        "KL", "LA", "LD", "MH", "ML", "MN", "MP", "MZ",
        "NL", "OD", "PB", "PY", "RJ", "SK", "TN", "TR",
        "TS", "UK", "UP", "WB"
    ]

    func parse(ocrText: String) -> PlateParseResult? {
        let normalized = PlateNormalizer.normalize(ocrText)
        guard !normalized.isEmpty else { return nil }

        // Try exact standard match
        if let result = tryStandardParse(normalized, confidence: 1.0) {
            return result
        }

        // Try exact BH series match
        if let result = tryBHParse(normalized, confidence: 1.0) {
            return result
        }

        // Try fuzzy matching with variants
        let variants = FuzzyMatcher.generateVariants(normalized)
        for variant in variants where variant != normalized {
            if let result = tryStandardParse(variant, confidence: 0.8) {
                return PlateParseResult(
                    rawText: ocrText,
                    normalizedPlate: result.normalizedPlate,
                    components: result.components,
                    confidence: result.confidence,
                    format: result.format
                )
            }
            if let result = tryBHParse(variant, confidence: 0.8) {
                return PlateParseResult(
                    rawText: ocrText,
                    normalizedPlate: result.normalizedPlate,
                    components: result.components,
                    confidence: result.confidence,
                    format: result.format
                )
            }
        }

        // Try loose pattern as last resort
        if let result = tryLooseParse(normalized) {
            return result
        }

        return nil
    }

    func validate(plate: String) -> Bool {
        parse(ocrText: plate) != nil
    }

    // MARK: - Private

    private func tryStandardParse(_ text: String, confidence: Double) -> PlateParseResult? {
        guard let regex = try? NSRegularExpression(pattern: Self.standardPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges == 5 else {
            return nil
        }

        let state = extractGroup(text, match: match, group: 1)
        let rto = extractGroup(text, match: match, group: 2)
        let series = extractGroup(text, match: match, group: 3)
        let number = extractGroup(text, match: match, group: 4)

        guard Self.validStateCodes.contains(state) else { return nil }

        let normalizedPlate = "\(state) \(rto) \(series) \(number)"

        return PlateParseResult(
            rawText: text,
            normalizedPlate: normalizedPlate,
            components: .indian(state: state, rtoCode: rto, series: series, number: number),
            confidence: confidence,
            format: .standard
        )
    }

    private func tryBHParse(_ text: String, confidence: Double) -> PlateParseResult? {
        guard let regex = try? NSRegularExpression(pattern: Self.bhSeriesPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges == 5 else {
            return nil
        }

        let year = extractGroup(text, match: match, group: 1)
        let number = extractGroup(text, match: match, group: 3)
        let category = extractGroup(text, match: match, group: 4)

        let normalizedPlate = "\(year) BH \(number) \(category)"

        return PlateParseResult(
            rawText: text,
            normalizedPlate: normalizedPlate,
            components: .indianBH(year: year, number: number, category: category),
            confidence: confidence,
            format: .bhSeries
        )
    }

    private func tryLooseParse(_ text: String) -> PlateParseResult? {
        guard let regex = try? NSRegularExpression(pattern: Self.looseStandardPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges == 5 else {
            return nil
        }

        let rawState = extractGroup(text, match: match, group: 1)
        let rawRTO = extractGroup(text, match: match, group: 2)
        let rawSeries = extractGroup(text, match: match, group: 3)
        let rawNumber = extractGroup(text, match: match, group: 4)

        // Try to fuzzy-match the state code
        guard let correctedState = FuzzyMatcher.bestStateMatch(rawState, validCodes: Self.validStateCodes) else {
            return nil
        }

        // Correct digits in RTO and number fields
        let correctedRTO = correctDigits(rawRTO)
        let correctedNumber = correctDigits(rawNumber)

        let normalizedPlate = "\(correctedState) \(correctedRTO) \(rawSeries) \(correctedNumber)"

        return PlateParseResult(
            rawText: text,
            normalizedPlate: normalizedPlate,
            components: .indian(state: correctedState, rtoCode: correctedRTO, series: rawSeries, number: correctedNumber),
            confidence: 0.6,
            format: .standard
        )
    }

    /// Replaces letter-like characters with their digit equivalents in a field expected to be numeric.
    private func correctDigits(_ text: String) -> String {
        text.map { char -> String in
            switch char {
            case "O", "o": "0"
            case "I", "i", "l", "L": "1"
            case "B": "8"
            case "S", "s": "5"
            case "Z", "z": "2"
            case "G", "g": "6"
            default: String(char)
            }
        }.joined()
    }

    private func extractGroup(_ text: String, match: NSTextCheckingResult, group: Int) -> String {
        guard let range = Range(match.range(at: group), in: text) else { return "" }
        return String(text[range])
    }
}
