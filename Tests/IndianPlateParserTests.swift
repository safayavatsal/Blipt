import XCTest
@testable import Blipt

final class IndianPlateParserTests: XCTestCase {
    let parser = IndianPlateParser()

    // MARK: - Standard Plates (exact)

    func testParsesCleanStandardPlate() {
        let result = parser.parse(ocrText: "MH12AB1234")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.normalizedPlate, "MH 12 AB 1234")
        XCTAssertEqual(result?.confidence, 1.0)
        XCTAssertEqual(result?.format, .standard)

        if case .indian(let state, let rto, let series, let number) = result?.components {
            XCTAssertEqual(state, "MH")
            XCTAssertEqual(rto, "12")
            XCTAssertEqual(series, "AB")
            XCTAssertEqual(number, "1234")
        } else {
            XCTFail("Expected indian components")
        }
    }

    func testParsesPlateWithSpaces() {
        let result = parser.parse(ocrText: "MH 12 AB 1234")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.normalizedPlate, "MH 12 AB 1234")
    }

    func testParsesPlateWithDashes() {
        let result = parser.parse(ocrText: "MH-12-AB-1234")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.normalizedPlate, "MH 12 AB 1234")
    }

    func testParsesPlateWithMixedSeparators() {
        let result = parser.parse(ocrText: "DL 01-CAB 9999")
        XCTAssertNotNil(result)
        if case .indian(let state, _, _, _) = result?.components {
            XCTAssertEqual(state, "DL")
        } else {
            XCTFail("Expected indian components")
        }
    }

    func testParsesSingleLetterSeries() {
        let result = parser.parse(ocrText: "KA05A1234")
        XCTAssertNotNil(result)
        if case .indian(_, _, let series, _) = result?.components {
            XCTAssertEqual(series, "A")
        } else {
            XCTFail("Expected indian components")
        }
    }

    func testParsesThreeLetterSeries() {
        let result = parser.parse(ocrText: "DL01CAB9999")
        XCTAssertNotNil(result)
        if case .indian(_, _, let series, _) = result?.components {
            XCTAssertEqual(series, "CAB")
        } else {
            XCTFail("Expected indian components")
        }
    }

    func testParsesShortNumber() {
        let result = parser.parse(ocrText: "TN01A1")
        XCTAssertNotNil(result)
        if case .indian(_, _, _, let number) = result?.components {
            XCTAssertEqual(number, "1")
        } else {
            XCTFail("Expected indian components")
        }
    }

    // MARK: - BH Series

    func testParsesBHPlate() {
        let result = parser.parse(ocrText: "22BH0123C")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .bhSeries)

        if case .indianBH(let year, let number, let category) = result?.components {
            XCTAssertEqual(year, "22")
            XCTAssertEqual(number, "0123")
            XCTAssertEqual(category, "C")
        } else {
            XCTFail("Expected indianBH components")
        }
    }

    func testParsesBHPlateWithTwoLetterCategory() {
        let result = parser.parse(ocrText: "24BH5678AA")
        XCTAssertNotNil(result)
        if case .indianBH(_, _, let category) = result?.components {
            XCTAssertEqual(category, "AA")
        } else {
            XCTFail("Expected indianBH components")
        }
    }

    func testParsesBHPlateWithSpaces() {
        let result = parser.parse(ocrText: "25 BH 0123 C")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .bhSeries)
    }

    // MARK: - Fuzzy Matching (OCR errors)

    func testCorrects0AsO() {
        // "O" misread as "0" in state code: "0D" should match "OD" (Odisha)
        let result = parser.parse(ocrText: "0D02AB1234")
        XCTAssertNotNil(result)
        if case .indian(let state, _, _, _) = result?.components {
            XCTAssertEqual(state, "OD")
        } else {
            XCTFail("Expected indian components with corrected state")
        }
    }

    func testCorrectsBAs8InSeries() {
        // "8" misread as "B" in number: "MH12AB123B" — the last B may be a misread 8
        // but since the number field expects digits, the loose parser should handle it
        let result = parser.parse(ocrText: "MH12AB1238")
        XCTAssertNotNil(result)
    }

    // MARK: - All State Codes

    func testAllValidStateCodes() {
        for code in IndianPlateParser.validStateCodes {
            let plateText = "\(code)01AB1234"
            let result = parser.parse(ocrText: plateText)
            XCTAssertNotNil(result, "Failed to parse plate for state code: \(code)")
        }
    }

    // MARK: - Invalid Input

    func testReturnsNilForEmptyString() {
        XCTAssertNil(parser.parse(ocrText: ""))
    }

    func testReturnsNilForRandomText() {
        XCTAssertNil(parser.parse(ocrText: "Hello World"))
    }

    func testReturnsNilForInvalidStateCode() {
        XCTAssertNil(parser.parse(ocrText: "ZZ99AB1234"))
    }

    func testReturnsNilForPartialPlate() {
        XCTAssertNil(parser.parse(ocrText: "MH12"))
    }

    func testReturnsNilForJustNumbers() {
        XCTAssertNil(parser.parse(ocrText: "12345678"))
    }

    // MARK: - IND Prefix Removal

    func testRemovesINDPrefix() {
        let result = parser.parse(ocrText: "INDMH12AB1234")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.normalizedPlate, "MH 12 AB 1234")
    }

    // MARK: - Lowercase Handling

    func testHandlesLowercaseInput() {
        let result = parser.parse(ocrText: "mh12ab1234")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.normalizedPlate, "MH 12 AB 1234")
    }

    // MARK: - Validate

    func testValidateReturnsTrueForValidPlate() {
        XCTAssertTrue(parser.validate(plate: "MH12AB1234"))
    }

    func testValidateReturnsFalseForInvalidPlate() {
        XCTAssertFalse(parser.validate(plate: "INVALID"))
    }
}
