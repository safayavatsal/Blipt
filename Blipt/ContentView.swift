import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
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
