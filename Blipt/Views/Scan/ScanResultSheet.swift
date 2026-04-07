import SwiftUI
import MapKit

struct ScanResultSheet: View {
    let plate: PlateParseResult
    let location: LocationInfo?
    let image: UIImage?
    let onScanAnother: () -> Void
    let onViewDetails: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Drag indicator
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Plate
            PlateVisualizerView(plate: plate)

            // Location
            if let location {
                locationCard(location)
            } else {
                notFoundCard
            }

            // Map snippet
            if let location, let coord = location.coordinate {
                MapSnippetView(
                    coordinate: CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng),
                    title: location.rtoName
                )
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Actions
            HStack(spacing: 12) {
                Button {
                    onViewDetails()
                } label: {
                    Label("Full Details", systemImage: "car.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BliptTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    shareCard()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
            }

            Button {
                onScanAnother()
            } label: {
                Label("Scan Another", systemImage: "camera.viewfinder")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private func locationCard(_ location: LocationInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.stateName)
                    .font(.title3.bold())
                Text(location.districtName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(location.rtoName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(location.stateCode)
                .font(.title2.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var notFoundCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Location not found")
                    .font(.headline)
                Text("Could not match this plate to a known RTO.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func shareCard() {
        guard let image = ShareCardView.renderImage(plate: plate, location: location) else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
