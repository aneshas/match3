import Foundation
import Observation

/// Whether all levels are unlocked (one-time purchase). Implementations are observable so
/// the Play screen unlocks the moment a purchase or restore completes. Until StoreKit is
/// wired in, a UserDefaults-backed stub stands in.
protocol UnlockStore: AnyObject, Observable {
    var isUnlocked: Bool { get }
}

@Observable
final class StubUnlockStore: UnlockStore {
    private let key = "allLevelsUnlocked"
    private(set) var isUnlocked: Bool

    init() {
        isUnlocked = DebugFlags.forceUnlocked || UserDefaults.standard.bool(forKey: key)
    }
}
