import SwiftUI

/// Blipt brand colors and typography.
/// Primary: Electric blue (#007AFF → deeper #0055D4)
/// Accent: Radar green (#34C759)
/// Surface: Dark navy for premium areas
enum BliptTheme {
    // MARK: - Colors
    static let accent = Color(red: 0.0, green: 0.478, blue: 1.0)        // #007AFF
    static let accentDeep = Color(red: 0.0, green: 0.333, blue: 0.831)   // #0055D4
    static let radarGreen = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
    static let premiumGold = Color(red: 1.0, green: 0.8, blue: 0.2)      // #FFCC33
    static let surfaceDark = Color(red: 0.067, green: 0.078, blue: 0.118) // #111420
    static let surfaceCard = Color(red: 0.11, green: 0.12, blue: 0.16)   // #1C1F29
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)

    // MARK: - Gradients
    static let premiumGradient = LinearGradient(
        colors: [accentDeep, Color(red: 0.4, green: 0.2, blue: 0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent, radarGreen],
        startPoint: .leading,
        endPoint: .trailing
    )
}
