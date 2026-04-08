import Foundation
import WidgetKit

/// Bridges scan data from the main app to Widget / Watch / CarPlay via shared App Group.
@MainActor
final class WidgetDataBridge {
    static let shared = WidgetDataBridge()

    private let suiteName = "group.com.blipt.shared"

    /// Call after every successful scan to update widget data.
    func updateWidgetData(from historyStore: ScanHistoryStore) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        let recentItems = historyStore.items.prefix(5).map { item in
            WidgetScanData(
                plate: item.normalizedPlate,
                stateName: item.stateName,
                districtName: item.districtName,
                timestamp: item.timestamp
            )
        }

        if let data = try? JSONEncoder().encode(Array(recentItems)) {
            defaults.set(data, forKey: "widget_recent_scans")
        }

        // Request widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct WidgetScanData: Codable {
    let plate: String
    let stateName: String?
    let districtName: String?
    let timestamp: Date
}
