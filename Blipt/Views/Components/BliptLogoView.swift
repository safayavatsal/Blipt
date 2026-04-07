import SwiftUI

/// Blipt logo — a radar blip / scanning pulse.
/// Concentric arcs radiating from a dot, representing "identify instantly."
struct BliptLogoView: View {
    var size: CGFloat = 80
    var animated: Bool = false

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer arcs (radar waves)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .trim(from: 0.05, to: 0.45)
                    .stroke(
                        BliptTheme.accent.opacity(0.3 + Double(i) * 0.2),
                        style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)
                    )
                    .frame(width: size * (0.5 + CGFloat(i) * 0.22),
                           height: size * (0.5 + CGFloat(i) * 0.22))
                    .rotationEffect(.degrees(-45))
                    .scaleEffect(animated && pulse ? 1.05 : 1.0)
                    .animation(
                        animated ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(i) * 0.15) : .default,
                        value: pulse
                    )
            }

            // Center dot (the "blip")
            Circle()
                .fill(BliptTheme.radarGreen)
                .frame(width: size * 0.2, height: size * 0.2)
                .shadow(color: BliptTheme.radarGreen.opacity(0.6), radius: size * 0.08)

            // Inner ring
            Circle()
                .stroke(BliptTheme.radarGreen.opacity(0.3), lineWidth: size * 0.03)
                .frame(width: size * 0.35, height: size * 0.35)
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated { pulse = true }
        }
    }
}

/// Blipt wordmark with logo
struct BliptBrandView: View {
    var logoSize: CGFloat = 48
    var showTagline: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            BliptLogoView(size: logoSize, animated: false)

            Text("Blipt")
                .font(.system(size: logoSize * 0.5, weight: .heavy, design: .rounded))
                .foregroundStyle(BliptTheme.accent)

            if showTagline {
                Text("Vehicle Intelligence, Instantly.")
                    .font(.system(size: logoSize * 0.18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Logo Sizes") {
    VStack(spacing: 40) {
        BliptLogoView(size: 120, animated: true)
        BliptLogoView(size: 60)
        BliptBrandView(logoSize: 80)
    }
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
