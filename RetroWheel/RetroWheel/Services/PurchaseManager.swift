import Foundation
import StoreKit
import Combine

/// Manages the single non-consumable lifetime unlock IAP and the "free to try" period.
///
/// - Bundle ID:  `com.marcustrise.retrowheel`
/// - Product ID: `com.marcustrise.retrowheel.unlock`
/// - IAP type:   Non-consumable (NOT an auto-renewable subscription)
/// - Free tier:  browse shell, play up to 3 local tracks per session
/// - Try period: free to try for 7 days from first launch; no payment required
/// - Unlocked:   $4.99 one-time purchase, full access forever
///
/// The trial start date is stored in the Keychain (not UserDefaults) so that
/// it survives app deletion and reinstallation on the same device.
@MainActor
final class PurchaseManager: ObservableObject {

    // MARK: - Public state

    @Published private(set) var isUnlocked: Bool = false
    @Published private(set) var isInTrial: Bool   = false
    @Published private(set) var trialDaysRemaining: Int = 0
    @Published private(set) var product: Product?
    @Published private(set) var purchaseInProgress: Bool = false
    @Published private(set) var restoreInProgress: Bool  = false

    /// True when the user has full access (either purchased or within the try period).
    var hasFullAccess: Bool { isUnlocked || isInTrial }

    // MARK: - Constants

    static let productID     = "com.marcustrise.retrowheel.unlock"
    static let freeSongLimit = 3

    private let tryPeriodDays    = 7
    private let tryStartKeychainKey = "retro_wheel_try_start_date"

    // MARK: - Init

    init() {
        Task { await setup() }
    }

    // MARK: - Setup

    private func setup() async {
        await loadProduct()
        await checkPurchaseStatus()
        recordTryStartIfNeeded()
        refreshTryStatus()
    }

    // MARK: - Product loading

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("PurchaseManager: failed to load product:", error)
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
                    isInTrial  = false
                }
            case .pending:
                break
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            print("PurchaseManager: purchase error:", error)
        }
    }

    // MARK: - Restore

    /// Syncs with the App Store and re-checks entitlements.
    /// Calling this is the correct way to restore non-consumable purchases.
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

    // MARK: - Try period (Keychain-backed)

    /// Writes the try-period start date to Keychain on the very first launch.
    /// Subsequent launches find the existing date and leave it untouched.
    private func recordTryStartIfNeeded() {
        guard KeychainHelper.loadDate(forKey: tryStartKeychainKey) == nil else { return }
        KeychainHelper.saveDate(Date(), forKey: tryStartKeychainKey)
    }

    /// Recomputes `isInTrial` and `trialDaysRemaining` from the Keychain date.
    func refreshTryStatus() {
        guard !isUnlocked else {
            isInTrial = false
            trialDaysRemaining = 0
            return
        }
        guard let start = KeychainHelper.loadDate(forKey: tryStartKeychainKey) else {
            isInTrial = false
            return
        }
        let elapsed   = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        let remaining = tryPeriodDays - elapsed
        if remaining > 0 {
            isInTrial          = true
            trialDaysRemaining = remaining
        } else {
            isInTrial          = false
            trialDaysRemaining = 0
        }
    }

    // MARK: - Verify existing purchases (StoreKit 2)

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                isUnlocked = true
                isInTrial  = false
                return
            }
        }
        isUnlocked = false
        refreshTryStatus()
    }

    // MARK: - Formatted price

    var formattedPrice: String {
        product?.displayPrice ?? "$4.99"
    }
}
