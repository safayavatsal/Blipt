import SwiftUI

struct PlateVisualizerView: View {
    let plate: PlateParseResult

    var body: some View {
        HStack(spacing: 0) {
            // Blue IND stripe (for standard Indian plates)
            if plate.format == .standard {
                VStack(spacing: 2) {
                    Text("IND")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 30)
                .frame(maxHeight: .infinity)
                .background(BliptTheme.accentDeep)
            }

            // Plate number (always black on white/yellow — matches real plates)
            Text(plate.normalizedPlate)
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(plateBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: BliptTheme.accent.opacity(0.15), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("License plate: \(plate.normalizedPlate)")
        .accessibilityAddTraits(.isStaticText)
    }

    private var plateBackground: Color {
        switch plate.format {
        case .standard: .white
        case .bhSeries: Color(red: 1.0, green: 0.85, blue: 0.0) // Indian yellow plate
        case .moroccan, .saudi: .white
        case .uae: .white
        case .uk: .white
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PlateVisualizerView(plate: PlateParseResult(
            rawText: "MH12AB1234",
            normalizedPlate: "MH 12 AB 1234",
            components: .indian(state: "MH", rtoCode: "12", series: "AB", number: "1234"),
            confidence: 0.95,
            format: .standard
        ))

        PlateVisualizerView(plate: PlateParseResult(
            rawText: "24BH5678C",
            normalizedPlate: "24 BH 5678 C",
            components: .indianBH(year: "24", number: "5678", category: "C"),
            confidence: 0.95,
            format: .bhSeries
        ))
    }
    .padding()
    .background(BliptTheme.surfaceDark)
    .preferredColorScheme(.dark)
}
