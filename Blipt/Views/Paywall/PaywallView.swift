import SwiftUI
import StoreKit

struct PaywallView: View {
    @State private var viewModel = SubscriptionViewModel()
    @State private var selectedProduct: Product?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                BliptTheme.surfaceDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        header

                        // Premium features list
                        premiumFeatures

                        // Product cards
                        productSection

                        // Subscribe button
                        subscribeButton

                        // Restore
                        Button {
                            Task { await viewModel.restore() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(BliptTheme.accent)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(BliptTheme.accent.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(BliptTheme.accent.opacity(0.4), lineWidth: 1)
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Error
                        if let error = viewModel.purchaseError {
                            ErrorBannerView(message: error)
                        }

                        // Legal
                        VStack(spacing: 4) {
                            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                            Text("[Terms of Service](https://blipt.app/terms) · [Privacy Policy](https://blipt.app/privacy)")
                        }
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .task {
                await viewModel.loadProducts()
                // Auto-select yearly (best value)
                selectedProduct = viewModel.manager.yearlyProduct ?? viewModel.manager.products.first
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            BliptLogoView(size: 80, animated: true)

            Text("Blipt Premium")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Unlock full vehicle intelligence")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 12)
    }

    // MARK: - Premium Features

    private var premiumFeatures: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureItem(icon: "car.fill", title: "Vehicle Details", subtitle: "Make, model, fuel type, class")
            featureItem(icon: "shield.checkered", title: "Insurance Status", subtitle: "Company, validity, active/expired")
            featureItem(icon: "exclamationmark.triangle.fill", title: "Challan History", subtitle: "Violations, amounts, payment status")
            featureItem(icon: "checkmark.seal.fill", title: "Fitness Certificate", subtitle: "Validity and expiry tracking")
        }
        .padding(20)
        .background(BliptTheme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func featureItem(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(BliptTheme.radarGreen)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
    }

    // MARK: - Product Cards

    private var productSection: some View {
        Group {
            if viewModel.manager.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(40)
            } else if viewModel.manager.products.isEmpty {
                Text("Products unavailable. Please try again later.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(20)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.manager.products, id: \.id) { product in
                        productCard(product)
                    }
                }
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isYearly = product.id == AppConstants.StoreKit.yearlyProductID

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedProduct = product
            }
        } label: {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? BliptTheme.accent : .white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(BliptTheme.accent)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if isYearly {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BliptTheme.premiumGold)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    if isYearly {
                        Text("per year")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Text("per month")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? BliptTheme.accent.opacity(0.12) : BliptTheme.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? BliptTheme.accent : .white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task { await viewModel.purchase(product) }
        } label: {
            Group {
                if viewModel.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe Now")
                        .font(.headline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [BliptTheme.accent, BliptTheme.accentDeep],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: BliptTheme.accent.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(selectedProduct == nil || viewModel.isPurchasing)
        .opacity(selectedProduct == nil ? 0.5 : 1.0)
    }
}
