import SwiftUI

/// Renders a branded share card image for a scanned plate result.
struct ShareCardView: View {
    let plate: PlateParseResult
    let location: LocationInfo?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                BliptLogoView(size: 28, animated: false)
                Text("Blipt")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(BliptTheme.accent)
                Spacer()
            }

            // Plate
            Text(plate.normalizedPlate)
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.gray.opacity(0.4), lineWidth: 2)
                )

            // Location
            if let location {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(BliptTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.stateName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(location.districtName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Text(location.stateCode)
                        .font(.title3.bold())
                        .foregroundStyle(BliptTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(BliptTheme.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Footer
            Divider().overlay(Color.white.opacity(0.1))
            Text("Scanned with Blipt — Vehicle Intelligence, Instantly.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(20)
        .background(BliptTheme.surfaceDark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: 340)
    }

    /// Render this view as a UIImage for sharing.
    @MainActor
    static func renderImage(plate: PlateParseResult, location: LocationInfo?) -> UIImage? {
        let view = ShareCardView(plate: plate, location: location)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

#Preview {
    ShareCardView(
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
            coordinate: Coordinate(lat: 18.52, lng: 73.86)
        )
    )
    .preferredColorScheme(.dark)
}
