import Foundation

@Observable @MainActor
final class HistoryViewModel {
    var searchQuery = ""

    let store: ScanHistoryStore
    let isPremium: Bool

    init(store: ScanHistoryStore = ScanHistoryStore(), isPremium: Bool = false) {
        self.store = store
        self.isPremium = isPremium
    }

    var visibleItems: [ScanHistoryItem] {
        let items = store.visibleItems(isPremium: isPremium)
        if searchQuery.isEmpty {
            return items
        }
        let q = searchQuery.lowercased()
        return items.filter {
            $0.plate.lowercased().contains(q) ||
            $0.normalizedPlate.lowercased().contains(q) ||
            ($0.stateName?.lowercased().contains(q) ?? false) ||
            ($0.districtName?.lowercased().contains(q) ?? false)
        }
    }

    var showUpgradePrompt: Bool {
        !isPremium && store.hasMoreThanFreeLimit
    }

    func delete(at offsets: IndexSet) {
        store.delete(at: offsets)
    }

    func clearAll() {
        store.clearAll()
    }
}
