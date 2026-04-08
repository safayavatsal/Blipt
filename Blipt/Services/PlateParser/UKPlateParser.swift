import Foundation

/// UK plate format (2001+): [2 area letters] [2 age digits] [3 random letters]
/// E.g., "AB51 CDE" — AB=area (West Midlands), 51=registered Sept 2001, CDE=random
/// Age identifiers: March reg = year (e.g., 24), September reg = year+50 (e.g., 74)
struct UKPlateParser: PlateParserProtocol {
    let country: Country = .uk

    // Standard UK format: LL DD LLL
    private static let pattern = #"^([A-Z]{2})\s*(\d{2})\s*([A-Z]{3})$"#

    private static let areaMap: [String: String] = [
        // A - Anglia
        "AA": "Peterborough", "AB": "Peterborough", "AC": "Peterborough",
        "AD": "Peterborough", "AE": "Peterborough",
        "AF": "Norwich", "AG": "Norwich", "AH": "Norwich",
        "AK": "Norwich", "AL": "Norwich", "AM": "Norwich", "AN": "Norwich",
        // B - Birmingham
        "BA": "Birmingham", "BB": "Birmingham", "BC": "Birmingham",
        "BD": "Birmingham", "BE": "Birmingham", "BF": "Birmingham",
        "BG": "Birmingham", "BH": "Birmingham", "BJ": "Birmingham",
        "BK": "Birmingham", "BL": "Birmingham", "BM": "Birmingham",
        "BN": "Birmingham", "BO": "Birmingham",
        // C - Cymru (Wales)
        "CA": "Cardiff", "CB": "Cardiff", "CC": "Cardiff",
        "CD": "Swansea", "CE": "Swansea", "CF": "Swansea",
        // D - Deeside
        "DA": "Chester", "DB": "Chester", "DC": "Chester",
        "DD": "Chester", "DE": "Chester", "DF": "Chester",
        "DG": "Shrewsbury", "DH": "Shrewsbury", "DJ": "Shrewsbury",
        "DK": "Shrewsbury",
        // E - Essex
        "EA": "Chelmsford", "EB": "Chelmsford", "EC": "Chelmsford",
        "ED": "Chelmsford", "EE": "Chelmsford", "EF": "Chelmsford",
        "EG": "Chelmsford",
        // L - London
        "LA": "London (Wimbledon)", "LB": "London (Wimbledon)",
        "LC": "London (Wimbledon)", "LD": "London (Wimbledon)",
        "LE": "London (Wimbledon)", "LF": "London (Wimbledon)",
        "LG": "London (Wimbledon)", "LH": "London (Wimbledon)",
        "LJ": "London (Wimbledon)", "LK": "London (Borehamwood)",
        "LL": "London (Borehamwood)", "LM": "London (Borehamwood)",
        "LN": "London (Borehamwood)",
        // M - Manchester
        "MA": "Manchester", "MB": "Manchester", "MC": "Manchester",
        "MD": "Manchester", "ME": "Manchester", "MF": "Manchester",
        "MG": "Manchester", "MH": "Manchester", "MJ": "Manchester",
        "MK": "Manchester", "ML": "Manchester", "MM": "Manchester",
        // S - Scotland
        "SA": "Edinburgh", "SB": "Edinburgh", "SC": "Edinburgh",
        "SD": "Edinburgh", "SE": "Edinburgh", "SF": "Edinburgh",
        "SG": "Glasgow", "SH": "Glasgow", "SJ": "Glasgow",
        "SK": "Glasgow", "SL": "Glasgow", "SM": "Glasgow",
        "SN": "Dundee", "SO": "Aberdeen",
        // Y - Yorkshire
        "YA": "Leeds", "YB": "Leeds", "YC": "Leeds",
        "YD": "Leeds", "YE": "Leeds", "YF": "Leeds",
        "YG": "Leeds", "YH": "Sheffield", "YJ": "Sheffield",
        "YK": "Sheffield",
    ]

    func parse(ocrText: String) -> PlateParseResult? {
        let normalized = PlateNormalizer.normalize(ocrText)
        guard normalized.count == 7 else { return nil }

        guard let regex = try? NSRegularExpression(pattern: Self.pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              match.numberOfRanges >= 4,
              let areaRange = Range(match.range(at: 1), in: normalized),
              let ageRange = Range(match.range(at: 2), in: normalized),
              let randomRange = Range(match.range(at: 3), in: normalized) else {
            return nil
        }

        let area = String(normalized[areaRange])
        let age = String(normalized[ageRange])
        let random = String(normalized[randomRange])

        // Validate age identifier (00-99)
        guard let ageNum = Int(age), (0...99).contains(ageNum) else { return nil }

        return PlateParseResult(
            rawText: ocrText,
            normalizedPlate: "\(area)\(age) \(random)",
            components: .uk(ageIdentifier: age, area: area, random: random),
            confidence: 0.85,
            format: .uk
        )
    }

    func validate(plate: String) -> Bool {
        parse(ocrText: plate) != nil
    }

    /// Decode the registration area from the 2-letter code.
    static func areaName(for code: String) -> String {
        areaMap[code.uppercased()] ?? "Unknown"
    }

    /// Decode the registration year from the age identifier.
    static func registrationYear(for age: String) -> String? {
        guard let num = Int(age) else { return nil }
        if num <= 50 {
            return "March 20\(String(format: "%02d", num))"
        } else {
            return "September 20\(String(format: "%02d", num - 50))"
        }
    }
}
