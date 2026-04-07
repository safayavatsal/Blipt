import Foundation

@MainActor
protocol CountryDataServiceProtocol {
    func loadData() async throws
    func lookup(plate: PlateParseResult) -> LocationInfo?
    func allRegions() -> [Region]
    func search(query: String) -> [Region]
}

struct Region: Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let subRegions: [SubRegion]
}

struct SubRegion: Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let district: String
    let coordinate: Coordinate?
}
