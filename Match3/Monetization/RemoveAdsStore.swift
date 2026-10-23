import Foundation

/// Whether the player has paid to remove ads. StoreKit 2 will back this later; the stub
/// just remembers a flag so the rest of the app can already honor it.
protocol RemoveAdsStore {
    var adsRemoved: Bool { get }
}

struct UserDefaultsRemoveAdsStore: RemoveAdsStore {
    private let key = "adsRemoved"
    var defaults: UserDefaults = .standard

    var adsRemoved: Bool { defaults.bool(forKey: key) }
}
