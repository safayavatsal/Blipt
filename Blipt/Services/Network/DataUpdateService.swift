import Foundation

@MainActor
final class DataUpdateService {
    private let apiClient: APIClient
    private let defaults = UserDefaults.standard

    private enum Keys {
        static func etag(for country: String) -> String { "data_etag_\(country)" }
        static func lastCheck(for country: String) -> String { "data_last_check_\(country)" }
    }

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    /// Check for data updates on launch. Skips if checked within last 24 hours.
    func checkForUpdates(country: Country) async {
        let code = country.rawValue
        let lastCheckKey = Keys.lastCheck(for: code)

        // Skip if checked recently (within 24h)
        if let lastCheck = defaults.object(forKey: lastCheckKey) as? Date,
           Date().timeIntervalSince(lastCheck) < 86400 {
            return
        }

        do {
            let updated = try await fetchDataIfChanged(country: country)
            defaults.set(Date(), forKey: lastCheckKey)
            if updated {
                // Data was updated — services will pick it up on next load
                NotificationCenter.default.post(name: .dataUpdated, object: country)
            }
        } catch {
            // Silently fail — bundled data is always available as fallback
        }
    }

    private func fetchDataIfChanged(country: Country) async throws -> Bool {
        let code = country.rawValue
        let etagKey = Keys.etag(for: code)
        let storedEtag = defaults.string(forKey: etagKey)

        let url = URL(string: "\(AppConstants.apiBaseURL)/countries/\(code)/data")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let etag = storedEtag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { return false }

        switch httpResponse.statusCode {
        case 304:
            // Not modified — data is current
            return false
        case 200:
            // New data — save to documents directory
            let newEtag = httpResponse.value(forHTTPHeaderField: "ETag")
            try saveData(data, for: country)
            if let etag = newEtag {
                defaults.set(etag, forKey: etagKey)
            }
            return true
        default:
            return false
        }
    }

    private func saveData(_ data: Data, for country: Country) throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename: String
        switch country {
        case .india: filename = "indian_rto_data.json"
        case .morocco: filename = "moroccan_cities.json"
        }
        let url = docs.appendingPathComponent(filename)
        try data.write(to: url)
    }
}

extension Notification.Name {
    static let dataUpdated = Notification.Name("com.blipt.dataUpdated")
}
