import SwiftUI

enum VerificationLevel {
    case verified    // RC active + insurance valid + no pending challans
    case caution     // RC active but insurance expiring or minor issues
    case issues      // RC inactive, insurance expired, or pending challans

    var label: String {
        switch self {
        case .verified: "Verified"
        case .caution: "Caution"
        case .issues: "Issues Found"
        }
    }

    var icon: String {
        switch self {
        case .verified: "checkmark.shield.fill"
        case .caution: "exclamationmark.shield.fill"
        case .issues: "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .verified: BliptTheme.radarGreen
        case .caution: .yellow
        case .issues: .red
        }
    }

    static func compute(from vehicle: VehicleInfo) -> VerificationLevel {
        var score = 0

        // RC status
        if vehicle.rcStatus.uppercased() == "ACTIVE" { score += 3 } else { return .issues }

        // Insurance
        if let insuranceUpto = vehicle.insuranceUpto {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: insuranceUpto).day ?? 0
            if days > 30 { score += 2 }
            else if days > 0 { score += 1 }
            else { return .issues }
        }

        // Fitness
        if let fitnessUpto = vehicle.fitnessUpto {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: fitnessUpto).day ?? 0
            if days > 90 { score += 2 }
            else if days > 0 { score += 1 }
        }

        // Challans
        let pendingChallans = vehicle.challans?.filter { $0.status == .pending }.count ?? 0
        if pendingChallans == 0 { score += 2 }
        else { score -= pendingChallans }

        if score >= 7 { return .verified }
        if score >= 4 { return .caution }
        return .issues
    }
}

struct VerificationBadgeView: View {
    let level: VerificationLevel
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: level.icon)
                .font(compact ? .caption : .subheadline)
            if !compact {
                Text(level.label)
                    .font(.caption.weight(.bold))
            }
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(level.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        VerificationBadgeView(level: .verified)
        VerificationBadgeView(level: .caution)
        VerificationBadgeView(level: .issues)
        VerificationBadgeView(level: .verified, compact: true)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
