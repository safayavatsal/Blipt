import Foundation

@Observable @MainActor
final class VehicleDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(VehicleInfo)
        case error(String)
        case usageLimitReached
    }

    var loadState: LoadState = .idle
    let plate: String
    let isPremium: Bool

    private let apiService: VahanAPIServiceProtocol
    private let connectivity: ConnectivityMonitor
    private let usageTracker: UsageTracker

    init(
        plate: String,
        isPremium: Bool,
        apiService: VahanAPIServiceProtocol = VahanAPIService(),
        connectivity: ConnectivityMonitor = ConnectivityMonitor(),
        usageTracker: UsageTracker = UsageTracker()
    ) {
        self.plate = plate
        self.isPremium = isPremium
        self.apiService = apiService
        self.connectivity = connectivity
        self.usageTracker = usageTracker
    }

    var isOffline: Bool {
        !connectivity.isConnected
    }

    var remainingLookups: Int {
        usageTracker.remainingFree
    }

    func fetchDetails() async {
        // Premium users: unlimited
        // Free users: check usage limit
        if !isPremium {
            guard usageTracker.recordLookup() else {
                loadState = .usageLimitReached
                return
            }
        }

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
