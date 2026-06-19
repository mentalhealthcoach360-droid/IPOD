import Foundation
import StoreKit

/// Manages the single non-consumable lifetime unlock IAP.
///
/// Monetization — one coherent model:
///   Free   : browse the retro interface, play up to 3 local tracks per session,
///            black shell only, no streaming, no playlists
///   Unlocked ($4.99 one-time): unlimited songs, all shell colours,
///            playlists, streaming library — no subscription, no recurring charge
///
/// - Bundle ID:  com.marcustrise.retrowheel
/// - Product ID: com.marcustrise.retrowheel.unlock
/// - IAP type:   Non-consumable (NOT an auto-renewable subscription)
@MainActor
final class PurchaseManager: ObservableObject {

    // MARK: - Public state

    @Published private(set) var isUnlocked: Bool        = false
    @Published private(set) var product: Product?
    @Published private(set) var purchaseInProgress: Bool = false
    @Published private(set) var restoreInProgress: Bool  = false

    /// True only when the user has completed the one-time purchase.
    var hasFullAccess: Bool { isUnlocked }

    // MARK: - Constants

    static let productID     = "com.marcustrise.retrowheel.unlock"
    static let freeSongLimit = 3

    // MARK: - Init

    init() {
        Task { await setup() }
    }

    private func setup() async {
        await loadProduct()
        await checkPurchaseStatus()
    }

    // MARK: - Product loading

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("PurchaseManager: product load failed:", error)
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product, !purchaseInProgress else { return }
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    isUnlocked = true
                }
            case .pending, .userCancelled: break
            @unknown default: break
            }
        } catch {
            print("PurchaseManager: purchase error:", error)
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        restoreInProgress = true
        defer { restoreInProgress = false }
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            print("PurchaseManager: restore error:", error)
        }
    }

    // MARK: - Entitlement check (StoreKit 2)

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                isUnlocked = true
                return
            }
        }
        isUnlocked = false
    }

    // MARK: - Helpers

    var formattedPrice: String { product?.displayPrice ?? "$4.99" }
}
