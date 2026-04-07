import Foundation

enum APIError: LocalizedError {
    case networkUnavailable
    case unauthorized
    case rateLimited(retryAfter: Int)
    case plateNotFound
    case serverError(statusCode: Int)
    case decodingError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            "No internet connection. Plate-to-location is still available offline."
        case .unauthorized:
            "Authentication failed. Please restart the app."
        case .rateLimited(let seconds):
            "Too many requests. Please try again in \(seconds) seconds."
        case .plateNotFound:
            "No vehicle found for this plate number."
        case .serverError(let code):
            "Server error (\(code)). Please try again later."
        case .decodingError:
            "Failed to read server response."
        case .unknown(let error):
            error.localizedDescription
        }
    }
}
