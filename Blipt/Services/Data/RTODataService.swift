import Foundation

@Observable @MainActor
final class RTODataService: CountryDataServiceProtocol {
    private var states: [IndianState] = []
    private var stateIndex: [String: IndianState] = [:]
    private var rtoIndex: [String: (IndianState, RTOOffice)] = [:]
    private var isLoaded = false

    func loadData() async throws {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: AppConstants.indianRTODataFile, withExtension: "json") else {
            throw DataServiceError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(RTODataFile.self, from: data)

        states = decoded.states.sorted { $0.name < $1.name }

        // Build lookup indexes
        for state in states {
            stateIndex[state.code] = state
            for rto in state.rtos {
                rtoIndex[rto.fullCode] = (state, rto)
            }
        }

        isLoaded = true
    }

    func lookup(plate: PlateParseResult) -> LocationInfo? {
        switch plate.components {
        case .indian(let state, let rtoCode, _, _):
            let fullCode = "\(state)\(rtoCode)"
            if let (stateInfo, rtoInfo) = rtoIndex[fullCode] {
                return LocationInfo(
                    stateName: stateInfo.name,
                    stateCode: stateInfo.code,
                    districtName: rtoInfo.district,
                    rtoName: rtoInfo.name,
                    coordinate: rtoInfo.coordinate ?? stateInfo.coordinate
                )
            }
            // Fall back to state-level match if RTO not found
            if let stateInfo = stateIndex[state] {
                return LocationInfo(
                    stateName: stateInfo.name,
                    stateCode: stateInfo.code,
                    districtName: "Unknown RTO (\(fullCode))",
                    rtoName: "RTO \(rtoCode)",
                    coordinate: stateInfo.coordinate
                )
            }
            return nil

        case .indianBH:
            return LocationInfo(
                stateName: "Bharat Series",
                stateCode: "BH",
                districtName: "National Permit",
                rtoName: "All India",
                coordinate: Coordinate(lat: 28.6139, lng: 77.2090) // New Delhi
            )

        case .moroccan:
            return nil // Handled by MoroccoDataService
        }
    }

    func allRegions() -> [Region] {
        states.map { state in
            Region(
                id: state.code,
                code: state.code,
                name: state.name,
                subRegions: state.rtos.map { rto in
                    SubRegion(
                        id: rto.fullCode,
                        code: rto.fullCode,
                        name: rto.name,
                        district: rto.district,
                        coordinate: rto.coordinate
                    )
                }
            )
        }
    }

    func search(query: String) -> [Region] {
        let query = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return allRegions() }

        return states.compactMap { state in
            let stateMatches = state.name.lowercased().contains(query) ||
                               state.code.lowercased().contains(query)

            let matchingRTOs = state.rtos.filter { rto in
                rto.fullCode.lowercased().contains(query) ||
                rto.name.lowercased().contains(query) ||
                rto.district.lowercased().contains(query)
            }

            if stateMatches {
                return Region(
                    id: state.code,
                    code: state.code,
                    name: state.name,
                    subRegions: state.rtos.map { rto in
                        SubRegion(id: rto.fullCode, code: rto.fullCode, name: rto.name, district: rto.district, coordinate: rto.coordinate)
                    }
                )
            } else if !matchingRTOs.isEmpty {
                return Region(
                    id: state.code,
                    code: state.code,
                    name: state.name,
                    subRegions: matchingRTOs.map { rto in
                        SubRegion(id: rto.fullCode, code: rto.fullCode, name: rto.name, district: rto.district, coordinate: rto.coordinate)
                    }
                )
            }

            return nil
        }
    }

    // MARK: - Direct accessors

    func state(for code: String) -> IndianState? {
        stateIndex[code]
    }

    func rto(for fullCode: String) -> (IndianState, RTOOffice)? {
        rtoIndex[fullCode]
    }

    var totalRTOCount: Int {
        states.reduce(0) { $0 + $1.rtos.count }
    }
}

// MARK: - JSON Structure

private struct RTODataFile: Codable {
    let version: String
    let lastUpdated: String
    let states: [IndianState]
}

enum DataServiceError: LocalizedError {
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound: "RTO data file not found in app bundle."
        }
    }
}
