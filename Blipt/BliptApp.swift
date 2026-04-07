import SwiftUI

@main
struct BliptApp: App {
    @State private var appState = AppState()

    init() {
        // Set global tint
        UITabBar.appearance().unselectedItemTintColor = .systemGray

        #if DEBUG
        AnalyticsService.shared.configure(provider: ConsoleAnalyticsProvider())
        #else
        // AnalyticsService.shared.configure(provider: TelemetryDeckProvider(appID: "YOUR_APP_ID"))
        #endif
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(BliptTheme.accent)
                .task {
                    await DataUpdateService().checkForUpdates(country: appState.selectedCountry)
                }
        }
    }
}
