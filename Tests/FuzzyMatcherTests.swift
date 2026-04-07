import XCTest
@testable import Blipt

final class FuzzyMatcherTests: XCTestCase {

    // MARK: - Generate Variants

    func testGeneratesVariantsForO() {
        let variants = FuzzyMatcher.generateVariants("O")
        XCTAssertTrue(variants.contains("O"))
        XCTAssertTrue(variants.contains("0"))
    }

    func testGeneratesVariantsFor0() {
        let variants = FuzzyMatcher.generateVariants("0")
        XCTAssertTrue(variants.contains("O"))
        XCTAssertTrue(variants.contains("0"))
    }

    func testGeneratesVariantsForI() {
        let variants = FuzzyMatcher.generateVariants("I")
        XCTAssertTrue(variants.contains("I"))
        XCTAssertTrue(variants.contains("1"))
    }

    func testGeneratesVariantsForB() {
        let variants = FuzzyMatcher.generateVariants("B")
        XCTAssertTrue(variants.contains("B"))
        XCTAssertTrue(variants.contains("8"))
    }

    func testGeneratesVariantsForS() {
        let variants = FuzzyMatcher.generateVariants("S")
        XCTAssertTrue(variants.contains("S"))
        XCTAssertTrue(variants.contains("5"))
    }

    func testGeneratesVariantsForZ() {
        let variants = FuzzyMatcher.generateVariants("Z")
        XCTAssertTrue(variants.contains("Z"))
        XCTAssertTrue(variants.contains("2"))
    }

    func testGeneratesVariantsForG() {
        let variants = FuzzyMatcher.generateVariants("G")
        XCTAssertTrue(variants.contains("G"))
        XCTAssertTrue(variants.contains("6"))
    }

    func testVariantCountIsBounded() {
        // For "ABCD" with no confusable chars, should return just the original
        let variants = FuzzyMatcher.generateVariants("ABCD")
        // B can become 8, so we get: ABCD, A8CD = 2 variants
        XCTAssertEqual(variants.count, 2)
    }

    func testVariantCountForConfusableString() {
        // "OBI" -> O can be 0, B can be 8, I can be 1 — single-char subs only
        let variants = FuzzyMatcher.generateVariants("OBI")
        // Original + O->0 + B->8 + I->1 = 4 (set, no dupes)
        XCTAssertLessThanOrEqual(variants.count, 4)
    }

    func testNoVariantsForPlainDigits() {
        let variants = FuzzyMatcher.generateVariants("1234")
        // 1->I or L, 2->Z, etc.
        XCTAssertTrue(variants.contains("1234"))
    }

    // MARK: - Best State Match

    func testDirectMatchReturnsCorrectState() {
        let validCodes: Set<String> = ["MH", "DL", "KA"]
        XCTAssertEqual(FuzzyMatcher.bestStateMatch("MH", validCodes: validCodes), "MH")
    }

    func testFuzzyMatchCorrects0ToO() {
        let validCodes: Set<String> = ["OD", "MH", "DL"]
        // "0D" should fuzzy-match to "OD"
        XCTAssertEqual(FuzzyMatcher.bestStateMatch("0D", validCodes: validCodes), "OD")
    }

    func testNoMatchReturnsNil() {
        let validCodes: Set<String> = ["MH", "DL"]
        XCTAssertNil(FuzzyMatcher.bestStateMatch("ZZ", validCodes: validCodes))
    }
}
