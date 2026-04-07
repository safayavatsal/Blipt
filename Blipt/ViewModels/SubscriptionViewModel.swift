import StoreKit

@Observable @MainActor
final class SubscriptionViewModel {
    let manager: SubscriptionManager

    var purchaseError: String?
    var isPurchasing = false

    init(manager: SubscriptionManager = SubscriptionManager()) {
        self.manager = manager
    }

    func loadProducts() async {
        await manager.loadProducts()
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        do {
            _ = try await manager.purchase(product)
        } catch {
            purchaseError = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        await manager.restore()
    }
}
