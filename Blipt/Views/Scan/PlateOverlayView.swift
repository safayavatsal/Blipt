import SwiftUI

struct PlateOverlayView: View {
    let detection: PlateDetector.Detection?
    let isConfirmed: Bool
    let geometrySize: CGSize

    var body: some View {
        ZStack {
            // Bounding box around detected plate
            if let detection {
                let rect = convertedRect(detection.boundingBox, in: geometrySize)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(isConfirmed ? .green : .yellow, lineWidth: 3)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .animation(.easeInOut(duration: 0.15), value: rect.origin.x)
                    .animation(.easeInOut(duration: 0.15), value: rect.origin.y)

                // Plate text label above the box
                Text(detection.parseResult.normalizedPlate)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isConfirmed ? Color.green : Color.yellow)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .position(x: rect.midX, y: rect.minY - 20)
                    .animation(.easeInOut(duration: 0.15), value: rect.midX)

                // Confidence indicator
                if isConfirmed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                        .position(x: rect.maxX + 20, y: rect.midY)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    /// Convert Vision coordinates (origin bottom-left, normalized 0-1) to SwiftUI coordinates (origin top-left).
    private func convertedRect(_ visionRect: CGRect, in size: CGSize) -> CGRect {
        let x = visionRect.origin.x * size.width
        let y = (1 - visionRect.origin.y - visionRect.height) * size.height
        let width = visionRect.width * size.width
        let height = visionRect.height * size.height

        // Add some padding
        let padX = width * 0.1
        let padY = height * 0.2
        return CGRect(
            x: x - padX,
            y: y - padY,
            width: width + padX * 2,
            height: height + padY * 2
        )
    }
}
