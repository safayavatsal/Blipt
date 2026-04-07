import Foundation

protocol VahanAPIServiceProtocol: Sendable {
    func fetchVehicleDetails(plate: String) async throws -> VehicleInfo
}

struct VahanAPIService: VahanAPIServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchVehicleDetails(plate: String) async throws -> VehicleInfo {
        let request = VehicleLookupRequest(plate: plate)
        let response: VahanAPIResponse = try await apiClient.post(
            path: "vehicle/lookup",
            body: request
        )

        guard response.success, let data = response.data else {
            if let error = response.error {
                if error.lowercased().contains("not found") {
                    throw APIError.plateNotFound
                }
                throw APIError.serverError(statusCode: 0)
            }
            throw APIError.plateNotFound
        }

        return data.toVehicleInfo()
    }
}
