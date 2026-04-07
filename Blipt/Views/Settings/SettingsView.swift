import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showPaywall = false
    @State private var showSubmission = false
    @State private var subscriptionManager = SubscriptionManager()

    var body: some View {
        @Bindable var state = appState

        NavigationStack {
            List {
                Section("Country") {
                    Picker("Region", selection: $state.selectedCountry) {
                        ForEach(Country.allCases) { country in
                            Text("\(country.flagEmoji) \(country.displayName)")
                                .tag(country)
                        }
                    }
                }

                Section("Subscription") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(appState.isPremium ? "Premium" : "Free")
                            .foregroundStyle(appState.isPremium ? .green : .secondary)
                    }
                    if !appState.isPremium {
                        Button("Upgrade to Premium") {
                            showPaywall = true
                        }
                    }
                    Button("Restore Purchases") {
                        Task { await subscriptionManager.restore() }
                    }
                }

                Section("Community") {
                    Button {
                        showSubmission = true
                    } label: {
                        Label("Report Missing or Incorrect Data", systemImage: "exclamationmark.bubble")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://blipt.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://blipt.app/terms")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSubmission) {
                DataSubmissionView(country: appState.selectedCountry)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
