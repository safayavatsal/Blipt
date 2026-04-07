import SwiftUI

struct FeatureComparisonView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Feature")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("Free")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 60)
                Text("Premium")
                    .font(.caption.bold())
                    .foregroundStyle(BliptTheme.premiumGold)
                    .frame(width: 70)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.white.opacity(0.05))

            Divider().overlay(Color.white.opacity(0.1))

            featureRow("Plate to Location", free: true, premium: true)
            featureRow("Browse RTOs", free: true, premium: true)
            featureRow("Photo Scanning", free: true, premium: true)
            featureRow("Live Camera Scan", free: true, premium: true)
            featureRow("Vehicle Details", free: false, premium: true)
            featureRow("Insurance Status", free: false, premium: true)
            featureRow("Challan History", free: false, premium: true)
            featureRow("Fitness Certificate", free: false, premium: true)
        }
        .background(BliptTheme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func featureRow(_ name: String, free: Bool, premium: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                checkmark(free)
                    .frame(width: 60)
                checkmark(premium)
                    .frame(width: 70)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider().overlay(Color.white.opacity(0.05))
        }
    }

    private func checkmark(_ available: Bool) -> some View {
        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundStyle(available ? BliptTheme.radarGreen : .white.opacity(0.15))
            .font(.subheadline)
    }
}
