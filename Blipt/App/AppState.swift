import SwiftUI

@Observable
final class AppState {
    var selectedCountry: Country = .india
    var isPremium: Bool = false
    var scanHistory: [ScanRecord] = []
}

struct ScanRecord: Identifiable, Codable {
    let id: UUID
    let plate: String
    let stateName: String?
    let districtName: String?
    let timestamp: Date

    init(plate: String, stateName: String?, districtName: String?, timestamp: Date = .now) {
        self.id = UUID()
        self.plate = plate
        self.stateName = stateName
        self.districtName = districtName
        self.timestamp = timestamp
    }
}
