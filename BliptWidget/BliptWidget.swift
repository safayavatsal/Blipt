import WidgetKit
import SwiftUI

// MARK: - Shared Data

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

    static func saveRecentScans(_ items: [WidgetScanItem]) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: "widget_recent_scans")
    }
}

// MARK: - Timeline Provider

struct BliptTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BliptWidgetEntry {
        BliptWidgetEntry(date: .now, scans: [
            WidgetScanItem(plate: "MH 12 AB 1234", stateName: "Maharashtra", districtName: "Pune", timestamp: .now)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (BliptWidgetEntry) -> Void) {
        let scans = WidgetDataStore.loadRecentScans()
        completion(BliptWidgetEntry(date: .now, scans: scans))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BliptWidgetEntry>) -> Void) {
        let scans = WidgetDataStore.loadRecentScans()
        let entry = BliptWidgetEntry(date: .now, scans: scans)
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct BliptWidgetEntry: TimelineEntry {
    let date: Date
    let scans: [WidgetScanItem]
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: BliptWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Blipt")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.blue)
            }

            if let scan = entry.scans.first {
                Spacer()

                Text(scan.plate)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)

                if let state = scan.stateName {
                    Text(state)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(scan.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Spacer()
                Text("No scans yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Open Blipt to scan")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(12)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: BliptWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Blipt")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.blue)
                Spacer()
                Text("Recent Scans")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.scans.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No scans yet — open Blipt to start")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.scans.prefix(3), id: \.plate) { scan in
                    HStack(spacing: 8) {
                        Text(scan.plate)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 3))

                        if let state = scan.stateName {
                            Text(state)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(scan.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
    }
}

// MARK: - Widget Configuration

struct BliptWidget: Widget {
    let kind: String = "BliptWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BliptTimelineProvider()) { entry in
            BliptWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Blipt")
        .description("See your recent plate scans.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BliptWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BliptWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct BliptWidgetBundle: WidgetBundle {
    var body: some Widget {
        BliptWidget()
    }
}
