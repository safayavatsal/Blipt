import Foundation

/// Tracks vehicle lookup usage for freemium gating.
/// Free users get a limited number of vehicle lookups per month.
@Observable @MainActor
final class UsageTracker {
    private let freeMonthlyLimit = 3
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let lookupCount = "usage_lookup_count"
        static let resetDate = "usage_reset_date"
        static let bonusLookups = "usage_bonus_lookups"
    }

    private(set) var lookupCount: Int = 0
    private(set) var bonusLookups: Int = 0

    init() {
        resetIfNewMonth()
        lookupCount = defaults.integer(forKey: Keys.lookupCount)
        bonusLookups = defaults.integer(forKey: Keys.bonusLookups)
    }

    var remainingFree: Int {
        max(0, freeMonthlyLimit + bonusLookups - lookupCount)
    }

    var hasFreeLookups: Bool {
        remainingFree > 0
    }

    var monthlyLimit: Int {
        freeMonthlyLimit + bonusLookups
    }

    /// Record a lookup. Returns true if allowed, false if limit reached.
    func recordLookup() -> Bool {
        resetIfNewMonth()
        guard hasFreeLookups else { return false }
        lookupCount += 1
        defaults.set(lookupCount, forKey: Keys.lookupCount)
        return true
    }

    /// Add bonus lookups (from referrals, promos, etc.)
    func addBonusLookups(_ count: Int) {
        bonusLookups += count
        defaults.set(bonusLookups, forKey: Keys.bonusLookups)
    }

    // MARK: - Monthly Reset

    private func resetIfNewMonth() {
        let calendar = Calendar.current
        let now = Date()

        if let lastReset = defaults.object(forKey: Keys.resetDate) as? Date {
            if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                lookupCount = 0
                defaults.set(0, forKey: Keys.lookupCount)
                defaults.set(now, forKey: Keys.resetDate)
            }
        } else {
            defaults.set(now, forKey: Keys.resetDate)
        }
    }
}
