import Foundation

@Observable @MainActor
final class ReferralManager {
    private let defaults = UserDefaults.standard
    private let bonusPerReferral = 3

    private enum Keys {
        static let referralCode = "referral_code"
        static let referralCount = "referral_count"
        static let hasRedeemedCode = "has_redeemed_code"
    }

    var referralCode: String {
        if let code = defaults.string(forKey: Keys.referralCode) {
            return code
        }
        let code = generateCode()
        defaults.set(code, forKey: Keys.referralCode)
        return code
    }

    var referralCount: Int {
        defaults.integer(forKey: Keys.referralCount)
    }

    var hasRedeemedCode: Bool {
        defaults.bool(forKey: Keys.hasRedeemedCode)
    }

    var shareMessage: String {
        "Try Blipt — scan any license plate and get instant vehicle intelligence! Use my code \(referralCode) for 3 free lookups. https://blipt.app/r/\(referralCode)"
    }

    /// Redeem someone else's referral code. Grants bonus lookups.
    func redeemCode(_ code: String, usageTracker: UsageTracker) -> Bool {
        // Can't redeem own code
        guard code != referralCode else { return false }
        // Can only redeem once
        guard !hasRedeemedCode else { return false }
        // Code must be 8 chars alphanumeric
        guard code.count == 8, code.allSatisfy({ $0.isLetter || $0.isNumber }) else { return false }

        usageTracker.addBonusLookups(bonusPerReferral)
        defaults.set(true, forKey: Keys.hasRedeemedCode)
        return true
    }

    /// Record that someone used our code (called via backend webhook in production).
    func recordReferral(usageTracker: UsageTracker) {
        let count = referralCount + 1
        defaults.set(count, forKey: Keys.referralCount)
        usageTracker.addBonusLookups(bonusPerReferral)
    }

    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No I, O, 0, 1 confusion
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}
