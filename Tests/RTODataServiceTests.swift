import XCTest
@testable import Blipt

@MainActor
final class RTODataServiceTests: XCTestCase {
    var service: RTODataService!

    override func setUp() async throws {
        service = RTODataService()
        try await service.loadData()
    }

    // MARK: - Load Data

    func testLoadDataSucceeds() {
        let regions = service.allRegions()
        XCTAssertFalse(regions.isEmpty, "allRegions should be non-empty after loading data")
    }

    // MARK: - Lookup

    func testLookupMH12ReturnsPune() {
        let plate = PlateParseResult(
            rawText: "MH 12 AB 1234",
            normalizedPlate: "MH 12 AB 1234",
            components: .indian(state: "MH", rtoCode: "12", series: "AB", number: "1234"),
            confidence: 1.0,
            format: .standard
        )
        let location = service.lookup(plate: plate)
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.stateName, "Maharashtra")
        XCTAssertEqual(location?.districtName, "Pune")
    }

    func testLookupDL01() {
        let plate = PlateParseResult(
            rawText: "DL 01 CAB 9999",
            normalizedPlate: "DL 01 CAB 9999",
            components: .indian(state: "DL", rtoCode: "01", series: "CAB", number: "9999"),
            confidence: 1.0,
            format: .standard
        )
        let location = service.lookup(plate: plate)
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.stateName, "Delhi")
        XCTAssertEqual(location?.stateCode, "DL")
    }

    func testLookupBHSeriesReturnsNationalPermit() {
        let plate = PlateParseResult(
            rawText: "24 BH 5678 C",
            normalizedPlate: "24 BH 5678 C",
            components: .indianBH(year: "24", number: "5678", category: "C"),
            confidence: 1.0,
            format: .bhSeries
        )
        let location = service.lookup(plate: plate)
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.stateName, "Bharat Series")
        XCTAssertEqual(location?.districtName, "National Permit")
    }

    func testLookupInvalidStateReturnsNil() {
        let plate = PlateParseResult(
            rawText: "XX 99 AB 1234",
            normalizedPlate: "XX 99 AB 1234",
            components: .indian(state: "XX", rtoCode: "99", series: "AB", number: "1234"),
            confidence: 1.0,
            format: .standard
        )
        let location = service.lookup(plate: plate)
        XCTAssertNil(location, "Lookup for invalid state 'XX' should return nil")
    }

    // MARK: - Search

    func testSearchFindsState() {
        let results = service.search(query: "Maharashtra")
        XCTAssertFalse(results.isEmpty, "Searching for 'Maharashtra' should return results")
        XCTAssertTrue(results.contains(where: { $0.name == "Maharashtra" }))
    }

    func testSearchFindsRTO() {
        let results = service.search(query: "Pune")
        XCTAssertFalse(results.isEmpty, "Searching for 'Pune' should return results")
    }

    func testSearchEmptyReturnsAll() {
        let allRegions = service.allRegions()
        let searchResults = service.search(query: "")
        XCTAssertEqual(searchResults.count, allRegions.count, "Empty search should return all regions")
    }

    // MARK: - Counts

    func testAllRegionsContains36States() {
        let regions = service.allRegions()
        // India has ~36 states/UTs; allow some flexibility
        XCTAssertGreaterThanOrEqual(regions.count, 30, "Should have at least 30 states/UTs")
        XCTAssertLessThanOrEqual(regions.count, 40, "Should have at most 40 states/UTs")
    }

    func testTotalRTOCountIsPositive() {
        XCTAssertGreaterThan(service.totalRTOCount, 0, "Total RTO count should be positive")
    }
}
