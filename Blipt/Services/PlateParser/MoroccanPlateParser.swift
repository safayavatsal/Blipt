import Foundation

struct MoroccanPlateParser: PlateParserProtocol {
    let country: Country = .morocco

    func parse(ocrText: String) -> PlateParseResult? {
        let normalized = PlateNormalizer.normalize(ocrText)
        guard normalized.count >= 2 else { return nil }

        let lastTwo = String(normalized.suffix(2))
        guard let cityCode = Int(lastTwo), (1...87).contains(cityCode) else {
            return nil
        }

        return PlateParseResult(
            rawText: ocrText,
            normalizedPlate: normalized,
            components: .moroccan(cityCode: cityCode),
            confidence: 0.9,
            format: .moroccan
        )
    }

    func validate(plate: String) -> Bool {
        parse(ocrText: plate) != nil
    }
}
