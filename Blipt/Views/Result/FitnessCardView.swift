import SwiftUI

struct FitnessCardView: View {
    let validUntil: Date?

    private var status: FitnessStatus {
        guard let validUntil else { return .unknown }
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
        if daysRemaining < 0 { return .expired }
        if daysRemaining < 90 { return .expiringSoon }
        return .valid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Fitness Certificate", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                Spacer()
                statusBadge
            }

            Divider()

            if let validUntil {
                HStack {
                    Text("Valid Until")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(validUntil.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.medium))
                }
                .font(.subheadline)
            } else {
                Text("No fitness certificate data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statusBadge: some View {
        Text(status.label)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color)
            .clipShape(Capsule())
    }

    private enum FitnessStatus {
        case valid, expiringSoon, expired, unknown

        var label: String {
            switch self {
            case .valid: "VALID"
            case .expiringSoon: "EXPIRING SOON"
            case .expired: "EXPIRED"
            case .unknown: "UNKNOWN"
            }
        }

        var color: Color {
            switch self {
            case .valid: .green
            case .expiringSoon: .yellow
            case .expired: .red
            case .unknown: .gray
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        FitnessCardView(validUntil: Date().addingTimeInterval(86400 * 365 * 5))
        FitnessCardView(validUntil: Date().addingTimeInterval(86400 * 60))
        FitnessCardView(validUntil: Date().addingTimeInterval(-86400 * 30))
        FitnessCardView(validUntil: nil)
    }
    .padding()
}
