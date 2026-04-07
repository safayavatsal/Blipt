import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var historyStore = ScanHistoryStore()

    var body: some View {
        TabView {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }

            HistoryView(store: historyStore)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "list.bullet.rectangle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(BliptTheme.accent)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
