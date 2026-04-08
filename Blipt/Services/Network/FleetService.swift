import Foundation

struct BulkLookupRequest: Codable {
    let plates: [String]
}

struct BulkLookupResult: Codable, Identifiable {
    let plate: String
    let success: Bool
    let data: VahanVehicleData?
    let error: String?

    var id: String { plate }
}

struct BulkLookupResponse: Codable {
    let total: Int
    let successful: Int
    let failed: Int
    let results: [BulkLookupResult]
}

struct FleetService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func bulkLookup(plates: [String]) async throws -> BulkLookupResponse {
        let request = BulkLookupRequest(plates: plates)
        return try await apiClient.post(path: "vehicle/bulk", body: request)
    }
}
