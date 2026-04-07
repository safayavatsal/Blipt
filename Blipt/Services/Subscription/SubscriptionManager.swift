import StoreKit

@Observable @MainActor
final class SubscriptionManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == AppConstants.StoreKit.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConstants.StoreKit.yearlyProductID }
    }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
    }

    // Note: cannot cancel in deinit since @MainActor; listener auto-cancels when Task is deallocated

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: SubscriptionProduct.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            products = []
        }
        isLoading = false
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    self?.purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                }
            }
        }
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        "Transaction verification failed."
    }
}
