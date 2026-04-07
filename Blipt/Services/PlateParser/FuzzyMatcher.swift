import Foundation

enum FuzzyMatcher {
    /// Characters commonly confused by OCR on license plates.
    private static let substitutions: [(Character, Character)] = [
        ("O", "0"),
        ("I", "1"),
        ("L", "1"),
        ("B", "8"),
        ("S", "5"),
        ("Z", "2"),
        ("G", "6"),
    ]

    /// Generates plausible variants of the input by applying single-character substitutions.
    /// Limited to single substitutions to avoid combinatorial explosion.
    static func generateVariants(_ text: String) -> [String] {
        var variants: Set<String> = [text]
        let chars = Array(text)

        for i in chars.indices {
            for (a, b) in substitutions {
                if chars[i] == a {
                    var modified = chars
                    modified[i] = b
                    variants.insert(String(modified))
                } else if chars[i] == b {
                    var modified = chars
                    modified[i] = a
                    variants.insert(String(modified))
                }
            }
        }

        return Array(variants)
    }

    /// Attempts to find the best matching state code from OCR text that may contain errors.
    static func bestStateMatch(_ candidate: String, validCodes: Set<String>) -> String? {
        // Direct match
        if validCodes.contains(candidate) {
            return candidate
        }

        // Try single-character variants
        for variant in generateVariants(candidate) where variant != candidate {
            if validCodes.contains(variant) {
                return variant
            }
        }

        return nil
    }
}
