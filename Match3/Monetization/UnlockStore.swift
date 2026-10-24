import Foundation
import Observation
import StoreKit

/// Whether all levels are unlocked (one non-consumable, one-time purchase, Family Sharing
/// enabled in App Store Connect). Observable so the Play screen unlocks the moment a
/// purchase or restore completes.
protocol UnlockStore: AnyObject, Observable {
    var isUnlocked: Bool { get }
    /// Localized price once the product has loaded, nil while loading or unavailable.
    var displayPrice: String? { get }
    var isBusy: Bool { get }
    @MainActor func purchase() async -> PurchaseOutcome
    @MainActor func restore() async -> Bool
}

enum PurchaseOutcome: Equatable {
    case unlocked
    /// Ask to Buy: a parent must approve on their device; the app unlocks when they do.
    case pending
    case cancelled
    case unavailable
    case failed(String)
}

/// StoreKit 2 implementation. Entitlements are the truth; a UserDefaults copy keeps the
/// unlock instant at launch and offline. `MATCH3_UNLOCKED=1` (Debug) behaves as if bought.
@Observable
final class StoreKitUnlockStore: UnlockStore {
    static let productID = "io.anes.match3.unlock"
    private static let cacheKey = "allLevelsUnlocked"

    private(set) var isUnlocked: Bool
    private(set) var displayPrice: String?
    private(set) var isBusy = false
    private var product: Product?
    private var updates: Task<Void, Never>?

    init() {
        isUnlocked = DebugFlags.forceUnlocked || UserDefaults.standard.bool(forKey: Self.cacheKey)
        updates = Task { [weak self] in
            // Purchases finishing elsewhere: Ask to Buy approvals, family members, refunds.
            for await result in Transaction.updates {
                guard let self, case .verified(let transaction) = result else { continue }
                await self.apply(transaction)
                await transaction.finish()
            }
        }
        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlements()
        }
    }

    @MainActor
    private func loadProduct() async {
        guard product == nil else { return }
        product = try? await Product.products(for: [Self.productID]).first
        displayPrice = product?.displayPrice
    }

    @MainActor
    private func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID, t.revocationDate == nil { owned = true }
        }
        setUnlocked(owned)
    }

    @MainActor
    private func apply(_ transaction: Transaction) {
        guard transaction.productID == Self.productID else { return }
        setUnlocked(transaction.revocationDate == nil)
    }

    @MainActor
    private func setUnlocked(_ owned: Bool) {
        UserDefaults.standard.set(owned, forKey: Self.cacheKey)
        isUnlocked = owned || DebugFlags.forceUnlocked
    }

    @MainActor
    func purchase() async -> PurchaseOutcome {
        await loadProduct()
        guard let product else { return .unavailable }
        isBusy = true
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result else { return .failed("The purchase could not be verified.") }
                apply(transaction)
                await transaction.finish()
                return .unlocked
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed("Unknown result.")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Re-reads purchases from the App Store (new device, reinstall, family member).
    @MainActor
    func restore() async -> Bool {
        isBusy = true
        defer { isBusy = false }
        try? await AppStore.sync()
        await refreshEntitlements()
        return isUnlocked
    }
}
