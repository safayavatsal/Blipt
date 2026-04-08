import Foundation

struct ScanHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let plate: String
    let normalizedPlate: String
    let stateName: String?
    let stateCode: String?
    let districtName: String?
    let rtoName: String?
    let country: String // "IN" or "MA"
    let format: String // "standard", "bhSeries", "moroccan"
    let confidence: Double
    let timestamp: Date
    var photoFilename: String?

    init(
        plate: String,
        normalizedPlate: String,
        stateName: String?,
        stateCode: String?,
        districtName: String?,
        rtoName: String?,
        country: String,
        format: String,
        confidence: Double,
        timestamp: Date = .now,
        photoFilename: String? = nil
    ) {
        self.id = UUID()
        self.plate = plate
        self.normalizedPlate = normalizedPlate
        self.stateName = stateName
        self.stateCode = stateCode
        self.districtName = districtName
        self.rtoName = rtoName
        self.country = country
        self.format = format
        self.confidence = confidence
        self.timestamp = timestamp
        self.photoFilename = photoFilename
    }
}

@Observable @MainActor
final class ScanHistoryStore {
    private(set) var items: [ScanHistoryItem] = []

    private let key = "scan_history"
    private let maxFreeItems = 5
    private let maxPremiumItems = 500

    init() {
        load()
    }

    func add(_ item: ScanHistoryItem) {
        // Avoid duplicates within last 30 seconds (same plate)
        if let last = items.first, last.plate == item.plate,
           item.timestamp.timeIntervalSince(last.timestamp) < 30 {
            return
        }

        items.insert(item, at: 0)

        // Cap at max premium items
        if items.count > maxPremiumItems {
            items = Array(items.prefix(maxPremiumItems))
        }

        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    func visibleItems(isPremium: Bool) -> [ScanHistoryItem] {
        if isPremium {
            return items
        }
        return Array(items.prefix(maxFreeItems))
    }

    var hasMoreThanFreeLimit: Bool {
        items.count > maxFreeItems
    }

    func search(query: String) -> [ScanHistoryItem] {
        guard !query.isEmpty else { return items }
        let q = query.lowercased()
        return items.filter {
            $0.plate.lowercased().contains(q) ||
            $0.normalizedPlate.lowercased().contains(q) ||
            ($0.stateName?.lowercased().contains(q) ?? false) ||
            ($0.districtName?.lowercased().contains(q) ?? false)
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ScanHistoryItem].self, from: data) else { return }
        items = decoded
    }
}
