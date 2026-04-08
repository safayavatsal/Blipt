import SwiftUI

/// Lightweight App Clip — scan a single plate and show result.
/// Triggered via NFC tag, QR code, or shared link.
@main
struct BliptAppClipApp: App {
    var body: some Scene {
        WindowGroup {
            AppClipScanView()
        }
    }
}

struct AppClipScanView: View {
    @State private var plateText = ""
    @State private var result: String?
    @State private var showFullApp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Branding
                VStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Blipt")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("Scan a License Plate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Manual entry (App Clip can't use camera without permission flow)
                TextField("Enter plate number", text: $plateText)
                    .font(.system(.title3, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Look Up") {
                    lookUp()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(plateText.count < 4)

                // Result
                if let result {
                    Text(result)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                // Full app upsell
                VStack(spacing: 8) {
                    Text("Want live camera scanning + vehicle details?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Get the Full App") {
                        showFullApp = true
                    }
                    .font(.headline)
                }
            }
            .padding(24)
            .appStoreOverlay(isPresented: $showFullApp) {
                SKOverlay.AppClipConfiguration(position: .bottom)
            }
        }
    }

    private func lookUp() {
        let parser = IndianPlateParser()
        guard let parseResult = parser.parse(ocrText: plateText) else {
            result = "Invalid plate format"
            return
        }

        // Inline lookup — App Clip bundles minimal data
        switch parseResult.components {
        case .indian(let state, _, _, _):
            result = "State: \(state) — Get the full app for details"
        case .indianBH:
            result = "Bharat Series (National Permit)"
        case .moroccan(let code):
            result = "Morocco — City Code \(code)"
        }
    }
}
