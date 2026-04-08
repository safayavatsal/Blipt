import SwiftUI

struct FleetView: View {
    @State private var viewModel = FleetViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "bus.doubledecker.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(BliptTheme.accent)
                            Text("Fleet Lookup")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Look up multiple plates at once (max 100)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        // Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plate Numbers")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.6))

                            TextEditor(text: $viewModel.plateInput)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)

                            Text("Enter one plate per line, or separate with commas")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                        }

                        // Parse + Look Up
                        Button {
                            viewModel.parsePlates()
                            Task { await viewModel.lookup() }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(.white)
                                        Text("Looking up \(viewModel.plates.count) plates...")
                                    }
                                } else {
                                    Label("Look Up All", systemImage: "magnifyingglass")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [BliptTheme.accent, BliptTheme.accentDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(viewModel.plateInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)

                        // Error
                        if let error = viewModel.errorMessage {
                            ErrorBannerView(message: error)
                        }

                        // Results
                        if !viewModel.results.isEmpty {
                            resultsSummary
                            resultsList
                            exportButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Fleet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var resultsSummary: some View {
        HStack(spacing: 16) {
            summaryBadge(count: viewModel.total, label: "Total", color: .white)
            summaryBadge(count: viewModel.successful, label: "Found", color: BliptTheme.radarGreen)
            summaryBadge(count: viewModel.failed, label: "Failed", color: .red)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func summaryBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var resultsList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.results) { result in
                HStack(spacing: 12) {
                    Text(result.plate)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    if result.success, let data = result.data {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(data.makerDescription) \(data.makerModel)")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(data.rcStatus)
                                .font(.caption2)
                                .foregroundStyle(data.rcStatus == "ACTIVE" ? .green : .red)
                        }
                    } else {
                        Text(result.error ?? "Not found")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.8))
                    }

                    Spacer()

                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.success ? .green : .red)
                        .font(.subheadline)
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var exportButton: some View {
        ShareLink(item: viewModel.csvExport) {
            Label("Export as CSV", systemImage: "arrow.down.doc")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BliptTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(BliptTheme.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BliptTheme.accent.opacity(0.3), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
