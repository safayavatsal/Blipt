import Foundation

@Observable @MainActor
final class MoroccoDataService: CountryDataServiceProtocol {
    private var cities: [MoroccanCity] = []
    private var cityIndex: [Int: MoroccanCity] = [:]
    private var isLoaded = false

    func loadData() async throws {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: AppConstants.moroccanCitiesDataFile, withExtension: "json") else {
            throw DataServiceError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(MoroccanCitiesFile.self, from: data)

        cities = decoded.cities.sorted { $0.name < $1.name }

        for city in cities {
            cityIndex[city.id] = city
        }

        isLoaded = true
    }

    func lookup(plate: PlateParseResult) -> LocationInfo? {
        guard case .moroccan(let cityCode) = plate.components else { return nil }

        guard let city = cityIndex[cityCode] else { return nil }

        return LocationInfo(
            stateName: "Morocco",
            stateCode: "MA",
            districtName: city.name,
            rtoName: "City Code \(cityCode)",
            coordinate: city.coordinate
        )
    }

    func allRegions() -> [Region] {
        // Group cities under a single "Morocco" region
        [Region(
            id: "MA",
            code: "MA",
            name: "Morocco",
            subRegions: cities.map { city in
                SubRegion(
                    id: String(city.id),
                    code: String(city.id),
                    name: city.name,
                    district: city.name,
                    coordinate: city.coordinate
                )
            }
        )]
    }

    func search(query: String) -> [Region] {
        let query = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return allRegions() }

        let matching = cities.filter { city in
            city.name.lowercased().contains(query) ||
            String(city.id) == query
        }

        guard !matching.isEmpty else { return [] }

        return [Region(
            id: "MA",
            code: "MA",
            name: "Morocco",
            subRegions: matching.map { city in
                SubRegion(
                    id: String(city.id),
                    code: String(city.id),
                    name: city.name,
                    district: city.name,
                    coordinate: city.coordinate
                )
            }
        )]
    }

    func city(for code: Int) -> MoroccanCity? {
        cityIndex[code]
    }

    var totalCityCount: Int {
        cities.count
    }
}
