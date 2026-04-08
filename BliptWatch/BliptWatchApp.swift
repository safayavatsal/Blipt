import SwiftUI

@main
struct BliptWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    @State private var recentScans: [WidgetScanItem] = []

    var body: some View {
        NavigationStack {
            if recentScans.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Blipt")
                        .font(.headline)
                    Text("No scans yet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Scan a plate on your iPhone")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                List(recentScans.prefix(5), id: \.plate) { scan in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scan.plate)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        if let state = scan.stateName {
                            Text(state)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(scan.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .navigationTitle("Blipt")
            }
        }
        .onAppear {
            loadScans()
        }
    }

    private func loadScans() {
        // Load from shared UserDefaults (App Group)
        recentScans = WidgetDataStore.loadRecentScans()
    }
}

// Shared data model (same as widget)
struct WidgetScanItem: Codable {
    let plate: String
    let stateName: String?
    let districtName: String?
    let timestamp: Date
}

enum WidgetDataStore {
    static let suiteName = "group.com.blipt.shared"

    static func loadRecentScans() -> [WidgetScanItem] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "widget_recent_scans"),
              let items = try? JSONDecoder().decode([WidgetScanItem].self, from: data) else {
            return []
        }
        return items
    }
}
