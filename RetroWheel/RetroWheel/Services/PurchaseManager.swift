import Foundation
import StoreKit
import Combine

/// Manages the single non-consumable lifetime unlock IAP and the 7-day free trial.
///
/// - Product ID: `com.yourcompany.RetroWheel.unlock`
/// - Free tier:  browse shell, play up to 3 local tracks per session
/// - Trial:      7-day full access, starts on first launch; no payment required
/// - Unlocked:   $4.99 one-time purchase, full access forever
@MainActor
final class PurchaseManager: ObservableObject {

    // MARK: - Public state

    @Published private(set) var isUnlocked: Bool = false
    @Published private(set) var isInTrial: Bool   = false
    @Published private(set) var trialDaysRemaining: Int = 0
    @Published private(set) var product: Product?
    @Published private(set) var purchaseInProgress: Bool = false
    @Published private(set) var restoreInProgress: Bool  = false

    var hasFullAccess: Bool { isUnlocked || isInTrial }

    // MARK: - Constants

    static let productID = "com.yourcompany.RetroWheel.unlock"
    static let freeSongLimit = 3

    private let trialDurationDays = 7
    private let trialStartKey     = "retro_wheel_trial_start"

    // MARK: - Init

    init() {
        Task { await setup() }
    }

    // MARK: - Setup

    private func setup() async {
        await loadProduct()
        await checkPurchaseStatus()
        startTrialIfNeeded()
        refreshTrialStatus()
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

    // MARK: - Trial

    /// Records the trial start date on first launch.
    private func startTrialIfNeeded() {
        guard UserDefaults.standard.object(forKey: trialStartKey) == nil else { return }
        UserDefaults.standard.set(Date(), forKey: trialStartKey)
    }

    /// Updates `isInTrial` and `trialDaysRemaining` based on stored start date.
    func refreshTrialStatus() {
        guard !isUnlocked else {
            isInTrial = false
            trialDaysRemaining = 0
            return
        }
        guard let start = UserDefaults.standard.object(forKey: trialStartKey) as? Date else {
            isInTrial = false
            return
        }
        let elapsed = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        let remaining = trialDurationDays - elapsed
        if remaining > 0 {
            isInTrial = true
            trialDaysRemaining = remaining
        } else {
            isInTrial = false
            trialDaysRemaining = 0
        }
    }

    // MARK: - Verify existing purchases

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

    // MARK: - Formatted price

    var formattedPrice: String {
        product?.displayPrice ?? "$4.99"
    }
}
