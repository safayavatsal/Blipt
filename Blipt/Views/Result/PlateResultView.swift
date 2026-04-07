import SwiftUI
import MapKit

struct PlateResultView: View {
    let plate: PlateParseResult
    let location: LocationInfo?
    let image: UIImage?

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var showPaywall = false
    @State private var showVehicleDetails = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Captured image
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                    }

                    // Plate visualizer
                    PlateVisualizerView(plate: plate)

                    // BH series info
                    if case .indianBH(let year, _, let category) = plate.components {
                        bhSeriesSection(year: year, category: category)
                    }

                    // Location info
                    if let location {
                        locationSection(location)
                    } else {
                        notFoundSection
                    }

                    // Map
                    if let location, let coord = location.coordinate {
                        MapSnippetView(
                            coordinate: CLLocationCoordinate2D(
                                latitude: coord.lat,
                                longitude: coord.lng
                            ),
                            title: location.rtoName
                        )
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Vehicle details (India only)
                    if location != nil && plate.format != .moroccan {
                        vehicleDetailsTeaser
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func locationSection(_ location: LocationInfo) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(BliptTheme.accent)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.stateName)
                        .font(.title2.bold())
                    Text(location.districtName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(location.stateCode)
                    .font(.title.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BliptTheme.accent.opacity(0.15))
                    .foregroundStyle(BliptTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            HStack {
                Label(location.rtoName, systemImage: "building.2")
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var notFoundSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Location not found")
                .font(.headline)
            Text("Could not match this plate to a known RTO.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func bhSeriesSection(year: String, category: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "globe.asia.australia.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bharat Series (National Permit)")
                        .font(.headline)
                    Text("Valid across all states without re-registration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("Year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("20\(year)")
                        .font(.title3.bold())
                }
                VStack(spacing: 2) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(bhCategoryName(category))
                        .font(.title3.bold())
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func bhCategoryName(_ code: String) -> String {
        switch code.uppercased() {
        case "A": "Non-transport"
        case "B": "Non-transport"
        case "C": "Non-transport"
        case "D": "Transport"
        case "E": "Transport"
        case "F": "Transport"
        default: code
        }
    }

    private var vehicleDetailsTeaser: some View {
        Group {
            if appState.isPremium {
                Button {
                    showVehicleDetails = true
                } label: {
                    Label("View Vehicle Details", systemImage: "car.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BliptTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                        .font(.headline)
                }
                .sheet(isPresented: $showVehicleDetails) {
                    VehicleDetailView(plate: plate.normalizedPlate.replacingOccurrences(of: " ", with: ""), isPremium: true)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Vehicle Details")
                        .font(.headline)
                    Text("Get make, model, insurance status, and challan history with Blipt Premium.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Unlock Premium")
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
            }
        }
    }
}

#Preview("Standard Plate") {
    PlateResultView(
        plate: PlateParseResult(
            rawText: "MH12AB1234",
            normalizedPlate: "MH 12 AB 1234",
            components: .indian(state: "MH", rtoCode: "12", series: "AB", number: "1234"),
            confidence: 0.95,
            format: .standard
        ),
        location: LocationInfo(
            stateName: "Maharashtra",
            stateCode: "MH",
            districtName: "Pune",
            rtoName: "Pune Central",
            coordinate: Coordinate(lat: 18.5204, lng: 73.8567)
        ),
        image: nil
    )
    .environment(AppState())
}

#Preview("BH Series") {
    PlateResultView(
        plate: PlateParseResult(
            rawText: "24BH5678C",
            normalizedPlate: "24 BH 5678 C",
            components: .indianBH(year: "24", number: "5678", category: "C"),
            confidence: 0.95,
            format: .bhSeries
        ),
        location: LocationInfo(
            stateName: "Bharat Series",
            stateCode: "BH",
            districtName: "National Permit",
            rtoName: "All India",
            coordinate: Coordinate(lat: 28.6139, lng: 77.2090)
        ),
        image: nil
    )
    .environment(AppState())
}

#Preview("Not Found") {
    PlateResultView(
        plate: PlateParseResult(
            rawText: "XX99ZZ9999",
            normalizedPlate: "XX 99 ZZ 9999",
            components: .indian(state: "XX", rtoCode: "99", series: "ZZ", number: "9999"),
            confidence: 0.6,
            format: .standard
        ),
        location: nil,
        image: nil
    )
    .environment(AppState())
}
