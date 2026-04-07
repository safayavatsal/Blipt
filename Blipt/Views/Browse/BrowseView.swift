import SwiftUI

struct BrowseView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = BrowseViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading data...")
                } else {
                    List {
                        ForEach(viewModel.filteredRegions) { region in
                            NavigationLink(value: region) {
                                HStack {
                                    Text(region.code)
                                        .font(.headline.monospaced())
                                        .foregroundStyle(BliptTheme.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(BliptTheme.accent.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading) {
                                        Text(region.name)
                                            .font(.headline)
                                        Text("\(region.subRegions.count) \(appState.selectedCountry == .india ? "RTOs" : "cities")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .navigationDestination(for: Region.self) { region in
                        StateDetailView(region: region)
                    }
                }
            }
            .navigationTitle("Browse")
            .searchable(
                text: $viewModel.searchQuery,
                prompt: appState.selectedCountry == .india
                    ? "Search states, RTOs, districts..."
                    : "Search cities..."
            )
            .task {
                await viewModel.loadData()
            }
            .onChange(of: appState.selectedCountry) { _, newCountry in
                viewModel.switchCountry(newCountry)
            }
        }
    }
}

#Preview {
    BrowseView()
        .environment(AppState())
}
