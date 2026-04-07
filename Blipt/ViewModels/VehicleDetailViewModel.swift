import Foundation

@Observable @MainActor
final class VehicleDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(VehicleInfo)
        case error(String)
    }

    var loadState: LoadState = .idle
    let plate: String
    let isPremium: Bool

    private let apiService: VahanAPIServiceProtocol
    private let connectivity: ConnectivityMonitor

    init(
        plate: String,
        isPremium: Bool,
        apiService: VahanAPIServiceProtocol = VahanAPIService(),
        connectivity: ConnectivityMonitor = ConnectivityMonitor()
    ) {
        self.plate = plate
        self.isPremium = isPremium
        self.apiService = apiService
        self.connectivity = connectivity
    }

    var isOffline: Bool {
        !connectivity.isConnected
    }

    func fetchDetails() async {
        guard isPremium else { return }

        guard connectivity.isConnected else {
            loadState = .error("No internet connection. Vehicle details require an active connection.")
            return
        }

        loadState = .loading

        do {
            let vehicle = try await apiService.fetchVehicleDetails(plate: plate)
            loadState = .loaded(vehicle)
        } catch let error as APIError {
            loadState = .error(error.localizedDescription)
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }
}
