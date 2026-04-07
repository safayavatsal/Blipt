import SwiftUI

struct InsuranceCardView: View {
    let company: String?
    let validUntil: Date?

    private var status: InsuranceStatus {
        guard let validUntil else { return .unknown }
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
        if daysRemaining < 0 { return .expired }
        if daysRemaining < 30 { return .expiringSoon }
        return .active
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Insurance", systemImage: "shield.checkered")
                    .font(.headline)
                Spacer()
                statusBadge
            }

            Divider()

            if let company {
                HStack {
                    Text("Company")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(company)
                        .font(.subheadline.weight(.medium))
                }
                .font(.subheadline)
            }

            if let validUntil {
                HStack {
                    Text("Valid Until")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(validUntil.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.medium))
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insurance status: \(status.label)\(company.map { ", company: \($0)" } ?? "")")
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

    private enum InsuranceStatus {
        case active, expiringSoon, expired, unknown

        var label: String {
            switch self {
            case .active: "ACTIVE"
            case .expiringSoon: "EXPIRING SOON"
            case .expired: "EXPIRED"
            case .unknown: "UNKNOWN"
            }
        }

        var color: Color {
            switch self {
            case .active: .green
            case .expiringSoon: .yellow
            case .expired: .red
            case .unknown: .gray
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        InsuranceCardView(company: "BAJAJ ALLIANZ", validUntil: Date().addingTimeInterval(86400 * 180))
        InsuranceCardView(company: "ICICI LOMBARD", validUntil: Date().addingTimeInterval(86400 * 15))
        InsuranceCardView(company: "NEW INDIA", validUntil: Date().addingTimeInterval(-86400 * 30))
        InsuranceCardView(company: nil, validUntil: nil)
    }
    .padding()
}
