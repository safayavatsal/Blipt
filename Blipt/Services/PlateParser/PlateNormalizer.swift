import Foundation

enum PlateNormalizer {
    /// Strips whitespace, dashes, dots, and normalizes text for parsing.
    static func normalize(_ text: String) -> String {
        var result = text
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove "IND" prefix (some plates have embossed country code)
        if result.hasPrefix("IND") {
            result = String(result.dropFirst(3))
        }

        // Remove all whitespace, dashes, dots, and special characters
        result = result.replacingOccurrences(of: "[\\s\\-\\.\\/|]", with: "", options: .regularExpression)

        return result
    }
}
