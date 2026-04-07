import Foundation

enum AppConstants {
    static let apiBaseURL = "https://blipt-api.railway.app/api/v1"
    static let indianRTODataFile = "indian_rto_data"
    static let moroccanCitiesDataFile = "moroccan_cities"

    enum StoreKit {
        static let monthlyProductID = "com.blipt.premium.monthly"
        static let yearlyProductID = "com.blipt.premium.yearly"
    }

    enum Limits {
        static let freeScansPerDay = 20
        static let freeScanHistoryCount = 5
        static let liveDetectionFPS = 5
        static let plateConfirmationCount = 3
    }
}
