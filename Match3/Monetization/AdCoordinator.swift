import Foundation

/// Something that can show a full-screen ad and return when it is dismissed.
/// The prototype ships only the no-op; an AdMob/AppLovin adapter plugs in here later.
protocol AdPresenter {
    func showInterstitial() async
}

struct NoOpAdPresenter: AdPresenter {
    func showInterstitial() async {}
}

/// Decides *when* an ad is shown. Keeping the policy here means the game flow never
/// knows about ad networks.
struct AdCoordinator {
    let presenter: AdPresenter
    let store: RemoveAdsStore
    /// Show an interstitial after every Nth completed level.
    var interval = 5

    /// Called after the Good Job screen, before the next level loads.
    func afterLevelCompleted(_ level: Int) async {
        guard !store.adsRemoved else { return }
        guard level % interval == 0 else { return }
        await presenter.showInterstitial()
    }
}
