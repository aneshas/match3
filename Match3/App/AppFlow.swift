import SwiftUI
import Match3Core

/// Top-level state machine: Play -> Level -> Good Job -> (ad hook) -> next Level -> ...
@MainActor
@Observable
final class AppFlow {
    enum Screen: Equatable {
        case play
        case level
        case goodJob
    }

    private(set) var screen: Screen = .play
    private(set) var session: GameSession?

    /// Levels finished so far; what the candy jar on the Play screen shows.
    var completedLevels: Int { progress.currentLevel - 1 }
    var currentLevel: Int { progress.currentLevel }
    var levelsFinishedLastWeek: Int { progress.levelsFinished(since: Date().addingTimeInterval(-7 * 24 * 3600)) }

    /// The caregiver panel is a sheet over the Play screen.
    var caregiverPanelShown = false

    private let progress: Progress
    private let ads: AdCoordinator
    private var advancing = false

    init(progress: Progress = Progress(),
         ads: AdCoordinator = AdCoordinator(presenter: NoOpAdPresenter(), store: UserDefaultsRemoveAdsStore())) {
        self.progress = progress
        self.ads = ads
        if DebugFlags.forgetSwipe { progress.forgetSwipe() }
        if DebugFlags.autoStart { play() }
    }

    /// Called from the Play button. Jumps straight into the current level.
    func play() {
        startLevel(DebugFlags.startLevel ?? progress.currentLevel)
        screen = .level
    }

    private func startLevel(_ level: Int) {
        let config = LevelConfig(level: level,
                                 assist: DebugFlags.assist ?? progress.assist,
                                 maxColors: Settings.shared.maxColors)
        let session = GameSession(config: config, swipeDemo: !progress.hasEverSwiped)
        session.onLevelComplete = { [weak self] in
            self?.levelCompleted()
        }
        session.onPlayerSwiped = { [weak self] in
            self?.progress.markSwiped()
        }
        self.session = session
    }

    private func levelCompleted() {
        guard let session else { return }
        progress.markCompleted(session.config.level)
        progress.assist = AssistPolicy.next(after: session.stats, current: progress.assist)
        advancing = false
        screen = .goodJob
    }

    /// Caregiver "start again".
    func resetProgress() {
        progress.reset()
        session = nil
        screen = .play
    }

    /// Called when the Good Job screen finishes (timeout or tap). Guarded so a tap and the
    /// timer firing together cannot skip a level.
    func continueAfterGoodJob() {
        guard !advancing, let finished = session?.config.level else { return }
        advancing = true
        Task {
            await ads.afterLevelCompleted(finished)
            startLevel(DebugFlags.startLevel.map { max($0, progress.currentLevel) } ?? progress.currentLevel)
            screen = .level
        }
    }
}
