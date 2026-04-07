import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let maxRetries = 2
    private let timeoutInterval: TimeInterval = 15

    init(
        baseURL: String = AppConstants.apiBaseURL,
        session: URLSession? = nil
    ) {
        self.baseURL = URL(string: baseURL)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = 30
        self.session = session ?? URLSession(configuration: config)
    }

    func post<T: Decodable>(
        path: String,
        body: some Encodable,
        bearerToken: String? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        return try await performWithRetry(request)
    }

    func get<T: Decodable>(
        path: String,
        bearerToken: String? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return try await performWithRetry(request)
    }

    // MARK: - Retry Logic

    private func performWithRetry<T: Decodable>(_ request: URLRequest) async throws -> T {
        var lastError: Error?

        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(for: .seconds(delay))
            }

            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown(URLError(.badServerResponse))
                }

                switch httpResponse.statusCode {
                case 200...299:
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    return try decoder.decode(T.self, from: data)
                case 401:
                    throw APIError.unauthorized
                case 404:
                    throw APIError.plateNotFound
                case 429:
                    let retryAfter = Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
                    throw APIError.rateLimited(retryAfter: retryAfter)
                default:
                    throw APIError.serverError(statusCode: httpResponse.statusCode)
                }
            } catch let error as APIError {
                // Don't retry auth or not-found errors
                switch error {
                case .unauthorized, .plateNotFound, .rateLimited:
                    throw error
                default:
                    lastError = error
                }
            } catch is DecodingError {
                throw APIError.decodingError
            } catch {
                lastError = error
            }
        }

        if let error = lastError {
            throw APIError.unknown(error)
        }
        throw APIError.networkUnavailable
    }
}
