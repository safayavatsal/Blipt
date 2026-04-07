import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.3 + phase * geometry.size.width * 1.6)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: phase
                    )
                }
                .clipped()
            }
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct LoadingOverlay: View {
    var body: some View {
        VStack(spacing: 16) {
            // Plate skeleton
            RoundedRectangle(cornerRadius: 6)
                .fill(.secondary.opacity(0.2))
                .frame(width: 220, height: 44)
                .shimmer()

            // Location skeleton
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 180, height: 20)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 120, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .shimmer()

            // Map skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.2))
                .frame(height: 140)
                .shimmer()
        }
        .padding()
    }
}

#Preview {
    LoadingOverlay()
}
