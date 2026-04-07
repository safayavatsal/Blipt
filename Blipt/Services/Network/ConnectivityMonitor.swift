import Network
import Foundation

@Observable @MainActor
final class ConnectivityMonitor {
    var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.blipt.connectivity")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
