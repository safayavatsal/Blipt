import Foundation

enum Country: String, Codable, CaseIterable, Identifiable {
    case india = "IN"
    case morocco = "MA"
    case uae = "AE"
    case saudiArabia = "SA"
    case uk = "GB"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .india: "India"
        case .morocco: "Morocco"
        case .uae: "UAE"
        case .saudiArabia: "Saudi Arabia"
        case .uk: "United Kingdom"
        }
    }

    var flagEmoji: String {
        switch self {
        case .india: "\u{1F1EE}\u{1F1F3}"
        case .morocco: "\u{1F1F2}\u{1F1E6}"
        case .uae: "\u{1F1E6}\u{1F1EA}"
        case .saudiArabia: "\u{1F1F8}\u{1F1E6}"
        case .uk: "\u{1F1EC}\u{1F1E7}"
        }
    }

    var dataFileName: String {
        switch self {
        case .india: AppConstants.indianRTODataFile
        case .morocco: AppConstants.moroccanCitiesDataFile
        case .uae: "uae_emirates"
        case .saudiArabia: "saudi_regions"
        case .uk: "uk_regions"
        }
    }

    var supportsVehicleIntelligence: Bool {
        switch self {
        case .india: true
        default: false
        }
    }
}
