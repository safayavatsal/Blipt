import SwiftUI

struct ErrorBannerView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            if let retryAction {
                Button("Retry", action: retryAction)
                    .font(.subheadline.bold())
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    VStack(spacing: 12) {
        ErrorBannerView(message: "No internet connection") {
            print("retry")
        }
        ErrorBannerView(message: "Plate not found in database")
    }
    .padding()
}
