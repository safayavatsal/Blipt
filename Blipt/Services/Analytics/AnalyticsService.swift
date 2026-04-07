import Foundation

/// Privacy-first analytics service. Never logs PII (plate numbers, locations).
/// Uses a simple protocol so the implementation can be swapped (TelemetryDeck, Firebase, etc.)
protocol AnalyticsProvider: Sendable {
    func send(event: String, parameters: [String: String])
}

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var provider: AnalyticsProvider?

    func configure(provider: AnalyticsProvider) {
        self.provider = provider
    }

    // MARK: - Events

    func scanCompleted(country: Country, method: ScanMethod) {
        send("scan_completed", parameters: [
            "country": country.rawValue,
            "method": method.rawValue,
        ])
    }

    func plateParsed(country: Country, format: String, confidence: String) {
        // Never log the actual plate number
        send("plate_parsed", parameters: [
            "country": country.rawValue,
            "format": format,
            "confidence_bucket": confidence,
        ])
    }

    func vehicleLookup(success: Bool) {
        send("vehicle_lookup", parameters: [
            "success": String(success),
        ])
    }

    func subscriptionStarted(plan: String) {
        send("subscription_started", parameters: [
            "plan": plan,
        ])
    }

    func countrySwitched(to country: Country) {
        send("country_switched", parameters: [
            "country": country.rawValue,
        ])
    }

    func paywallViewed() {
        send("paywall_viewed", parameters: [:])
    }

    func paywallDismissed() {
        send("paywall_dismissed", parameters: [:])
    }

    func browseSearched(country: Country) {
        send("browse_searched", parameters: [
            "country": country.rawValue,
        ])
    }

    // MARK: - Private

    private func send(_ event: String, parameters: [String: String]) {
        provider?.send(event: event, parameters: parameters)
    }

    enum ScanMethod: String {
        case camera
        case photoLibrary
    }
}

// MARK: - Console Provider (development)

struct ConsoleAnalyticsProvider: AnalyticsProvider {
    func send(event: String, parameters: [String: String]) {
        #if DEBUG
        print("[Analytics] \(event): \(parameters)")
        #endif
    }
}

// MARK: - TelemetryDeck Provider (production stub)
// To use: `import TelemetryDeck` and implement with real SDK

struct TelemetryDeckProvider: AnalyticsProvider {
    let appID: String

    func send(event: String, parameters: [String: String]) {
        // TelemetryDeck.signal(event, parameters: parameters)
        // Requires TelemetryDeck Swift SDK — add via SPM when ready
    }
}
