import Foundation

enum Country: String, Codable, CaseIterable, Identifiable {
    case india = "IN"
    case morocco = "MA"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .india: "India"
        case .morocco: "Morocco"
        }
    }

    var flagEmoji: String {
        switch self {
        case .india: "\u{1F1EE}\u{1F1F3}"
        case .morocco: "\u{1F1F2}\u{1F1E6}"
        }
    }

    var dataFileName: String {
        switch self {
        case .india: AppConstants.indianRTODataFile
        case .morocco: AppConstants.moroccanCitiesDataFile
        }
    }
}
