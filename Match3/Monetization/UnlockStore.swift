import Foundation

/// Whether all levels are unlocked (one-time purchase). Until StoreKit is wired in, a
/// UserDefaults-backed stub stands in so the rest of the app can already honor it.
protocol UnlockStore: AnyObject {
    var isUnlocked: Bool { get }
}

final class StubUnlockStore: UnlockStore {
    private let key = "allLevelsUnlocked"
    var isUnlocked: Bool {
        if DebugFlags.forceUnlocked { return true }
        return UserDefaults.standard.bool(forKey: key)
    }
}
