import Foundation

@Observable @MainActor
final class FleetViewModel {
    var plateInput = ""
    var plates: [String] = []
    var results: [BulkLookupResult] = []
    var isLoading = false
    var errorMessage: String?

    var total: Int = 0
    var successful: Int = 0
    var failed: Int = 0

    private let fleetService = FleetService()

    /// Parse plate input (comma or newline separated).
    func parsePlates() {
        let separators = CharacterSet.newlines.union(.init(charactersIn: ",;"))
        plates = plateInput
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            .filter { !$0.isEmpty }

        // Cap at 100
        if plates.count > 100 {
            plates = Array(plates.prefix(100))
        }
    }

    func lookup() async {
        guard !plates.isEmpty else {
            errorMessage = "Enter at least one plate number."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await fleetService.bulkLookup(plates: plates)
            results = response.results
            total = response.total
            successful = response.successful
            failed = response.failed
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Export results as CSV string.
    var csvExport: String {
        var csv = "Plate,Status,Make,Model,Fuel,Class,RC Status,Insurance Until,Error\n"
        for r in results {
            if r.success, let d = r.data {
                csv += "\(r.plate),OK,\(d.makerDescription),\(d.makerModel),\(d.fuelType),\(d.vehicleClass),\(d.rcStatus),\(d.insuranceUpto ?? ""),\n"
            } else {
                csv += "\(r.plate),FAILED,,,,,,\(r.error ?? "")\n"
            }
        }
        return csv
    }
}
