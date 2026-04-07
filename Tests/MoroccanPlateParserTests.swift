import XCTest
@testable import Blipt

final class MoroccanPlateParserTests: XCTestCase {
    let parser = MoroccanPlateParser()

    // MARK: - Valid Plates

    func testParsesSingleDigitCityPadded() {
        // After normalization "12345A01" → suffix(2) = "01" → cityCode 1
        let result = parser.parse(ocrText: "12345-A-01")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.components, .moroccan(cityCode: 1))
    }

    func testParsesDoubleDigitCity() {
        let result = parser.parse(ocrText: "12345-A-42")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.components, .moroccan(cityCode: 42))
    }

    func testParsesCasablanca() {
        // Casablanca is code 2
        let result = parser.parse(ocrText: "12345-A-02")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.components, .moroccan(cityCode: 2))
    }

    func testParsesLastCity87() {
        let result = parser.parse(ocrText: "ABC87")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.components, .moroccan(cityCode: 87))
    }

    func testParsesCity1() {
        let result = parser.parse(ocrText: "ABC01")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.components, .moroccan(cityCode: 1))
    }

    func testFormatIsMoroccan() {
        let result = parser.parse(ocrText: "12345-A-42")
        XCTAssertEqual(result?.format, .moroccan)
    }

    func testCountryIsMorocco() {
        XCTAssertEqual(parser.country, .morocco)
    }

    // MARK: - All 87 Cities Valid

    func testAllCityCodesValid() {
        for code in 1...87 {
            let padded = String(format: "%02d", code)
            let result = parser.parse(ocrText: "ABC\(padded)")
            XCTAssertNotNil(result, "City code \(code) should be valid")
            if case .moroccan(let parsed) = result?.components {
                XCTAssertEqual(parsed, code)
            }
        }
    }

    // MARK: - Invalid Plates

    func testRejectsCode0() {
        let result = parser.parse(ocrText: "ABC00")
        XCTAssertNil(result)
    }

    func testRejectsCode88() {
        let result = parser.parse(ocrText: "ABC88")
        XCTAssertNil(result)
    }

    func testRejectsCode99() {
        let result = parser.parse(ocrText: "ABC99")
        XCTAssertNil(result)
    }

    func testRejectsEmptyString() {
        XCTAssertNil(parser.parse(ocrText: ""))
    }

    func testRejectsSingleChar() {
        XCTAssertNil(parser.parse(ocrText: "A"))
    }

    func testRejectsLettersOnly() {
        XCTAssertNil(parser.parse(ocrText: "ABCDE"))
    }

    // MARK: - Validate

    func testValidateReturnsTrueForValid() {
        XCTAssertTrue(parser.validate(plate: "12345-A-42"))
    }

    func testValidateReturnsFalseForInvalid() {
        XCTAssertFalse(parser.validate(plate: "ABC00"))
    }
}
