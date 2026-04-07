import Foundation

@Observable @MainActor
final class PaywallManager {
    let subscriptionManager: SubscriptionManager

    var isPremium: Bool {
        subscriptionManager.isPremium
    }

    init(subscriptionManager: SubscriptionManager = SubscriptionManager()) {
        self.subscriptionManager = subscriptionManager
    }

    enum Feature {
        case vehicleDetails
        case insuranceStatus
        case challanHistory
        case fitnessCertificate
        case unlimitedScans
    }

    func canAccess(_ feature: Feature) -> Bool {
        switch feature {
        case .vehicleDetails, .insuranceStatus, .challanHistory, .fitnessCertificate:
            return isPremium
        case .unlimitedScans:
            return isPremium
        }
    }
}
