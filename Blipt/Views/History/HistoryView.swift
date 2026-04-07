import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: HistoryViewModel
    @State private var showPaywall = false
    @State private var showClearConfirm = false

    init(store: ScanHistoryStore = ScanHistoryStore()) {
        _viewModel = State(initialValue: HistoryViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.store.items.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .background(Color.black)
            .navigationTitle("History")
            .searchable(text: $viewModel.searchQuery, prompt: "Search plates, states...")
            .toolbar {
                if !viewModel.store.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            showClearConfirm = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .alert("Clear All History?", isPresented: $showClearConfirm) {
                Button("Clear All", role: .destructive) { viewModel.clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all scan history.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var historyList: some View {
        List {
            ForEach(viewModel.visibleItems) { item in
                HistoryRowView(item: item)
            }
            .onDelete { offsets in
                viewModel.delete(at: offsets)
            }

            // Upgrade prompt
            if viewModel.showUpgradePrompt {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundStyle(BliptTheme.accent)
                        Text("Showing last 5 scans")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("Upgrade to Premium for unlimited history")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Button {
                            showPaywall = true
                        } label: {
                            Text("Unlock History")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(BliptTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(BliptTheme.accent.opacity(0.4))
            Text("No Scans Yet")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Your scanned plates will appear here")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
        }
    }
}

struct HistoryRowView: View {
    let item: ScanHistoryItem

    var body: some View {
        HStack(spacing: 14) {
            // Plate badge
            Text(item.normalizedPlate)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                if let state = item.stateName {
                    Text(state)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
                if let district = item.districtName {
                    Text(district)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            Text(item.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.white.opacity(0.04))
    }
}

#Preview {
    HistoryView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
