import Foundation

@Observable @MainActor
final class ResultViewModel {
    let plate: PlateParseResult
    let location: LocationInfo?

    private let dataService: RTODataService

    init(plate: PlateParseResult, dataService: RTODataService = RTODataService()) {
        self.plate = plate
        self.dataService = dataService
        self.location = dataService.lookup(plate: plate)
    }

    var stateInfo: IndianState? {
        switch plate.components {
        case .indian(let state, _, _, _):
            return dataService.state(for: state)
        default:
            return nil
        }
    }

    var isBHSeries: Bool {
        if case .indianBH = plate.components { return true }
        return false
    }

    var formattedPlate: String {
        plate.normalizedPlate
    }
}
