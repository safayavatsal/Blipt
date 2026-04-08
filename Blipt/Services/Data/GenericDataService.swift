import Foundation

/// Fallback data service for countries without bundled RTO/city data.
/// Returns location from parsed plate components only (state/emirate/region).
@Observable @MainActor
final class GenericDataService: CountryDataServiceProtocol {
    private let country: Country

    init(country: Country) {
        self.country = country
    }

    func loadData() async throws {
        // No bundled data to load
    }

    func lookup(plate: PlateParseResult) -> LocationInfo? {
        switch plate.components {
        case .uae(let emirate, _, let number):
            return LocationInfo(
                stateName: emirate,
                stateCode: "AE",
                districtName: emirate,
                rtoName: "Plate \(number)",
                coordinate: nil
            )
        case .saudi(let region, _, let number):
            return LocationInfo(
                stateName: region,
                stateCode: "SA",
                districtName: region,
                rtoName: "Plate \(number)",
                coordinate: nil
            )
        case .uk(let age, let area, _):
            let areaName = UKPlateParser.areaName(for: area)
            let year = UKPlateParser.registrationYear(for: age) ?? age
            return LocationInfo(
                stateName: areaName,
                stateCode: "GB",
                districtName: year,
                rtoName: "DVLA \(area)",
                coordinate: nil
            )
        default:
            return nil
        }
    }

    func allRegions() -> [Region] {
        [Region(id: country.rawValue, code: country.rawValue, name: country.displayName, subRegions: [])]
    }

    func search(query: String) -> [Region] {
        allRegions()
    }
}
