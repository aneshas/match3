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
        case goodNight  // caregiver session timer ran out
    }

    private(set) var screen: Screen = .play {
        didSet {
            guard screen != oldValue else { return }
            switch screen {
            case .play, .level: MusicPlayer.shared.next()
            case .goodJob: MusicPlayer.shared.fadeOutQuickly()
            case .goodNight: MusicPlayer.shared.stop()
            }
        }
    }
    private(set) var session: GameSession?

    /// Levels finished so far; what the candy jar on the Play screen shows.
    var completedLevels: Int { progress.currentLevel - 1 }
    var currentLevel: Int { progress.currentLevel }
    var levelsFinishedLastWeek: Int { progress.levelsFinished(since: Date().addingTimeInterval(-7 * 24 * 3600)) }

    /// The caregiver panel is a sheet over the Play screen.
    var caregiverPanelShown = false

    /// Rows the current screen can show at the 7-column candy size; set by `RootView` from
    /// the window geometry (see `BoardFit`). Levels are clamped to it when they start.
    var boardMaxRows = LevelConfig.maxRows

    private let progress: Progress
    let unlock: UnlockStore
    private var advancing = false
    private var sessionStart: Date?
    /// The palette prepared for the next level while the current one is played (its newcomer
    /// is the candy at the end of the bar), so the promise on the bar is kept.
    private var nextPalette: CandyArt.Palette?

    /// Levels playable without the purchase. The last free level stays playable forever.
    static let freeLevels = 18
    var freeLevels: Int { DebugFlags.freeLevels ?? AppFlow.freeLevels }

    /// True when the player has finished every free level and nothing was bought.
    var isAtLock: Bool { !unlock.isUnlocked && progress.currentLevel > freeLevels }

    init(progress: Progress = Progress(), unlock: UnlockStore = StoreKitUnlockStore()) {
        self.progress = progress
        self.unlock = unlock
        if DebugFlags.forgetSwipe { progress.forgetSwipe() }
        // MATCH3_AUTOSTART is honored by RootView once the window size is known, so the
        // level gets the same row cap a real Play tap would.
    }

    /// Called from the Play button. Jumps straight into the current level.
    func play() {
        guard !isAtLock else { return }  // the Play button is shown locked; a caregiver must unlock or reset
        sessionStart = Date()
        startLevel(DebugFlags.startLevel ?? progress.currentLevel)
        screen = .level
    }

    /// True once the caregiver's session length has elapsed. Checked only between levels.
    private var sessionIsOver: Bool {
        guard let start = sessionStart else { return false }
        let elapsed = Date().timeIntervalSince(start)
        if let seconds = DebugFlags.sessionSeconds { return elapsed >= Double(seconds) }
        let minutes = Settings.shared.sessionMinutes
        return minutes > 0 && elapsed >= Double(minutes) * 60
    }

    /// Home button on the level screen: back to Play. The unfinished level is simply dropped.
    func goHome() {
        session = nil
        sessionStart = nil
        nextPalette = nil
        screen = .play
    }

    /// After the good-night screen: back to Play. Pressing Play starts a fresh session.
    func endSession() {
        session = nil
        sessionStart = nil
        screen = .play
    }

    private func startLevel(_ level: Int) {
        let config = LevelConfig(level: level,
                                 assist: DebugFlags.assist ?? progress.assist,
                                 maxColors: Settings.shared.maxColors,
                                 maxRows: boardMaxRows)
        // Use the palette promised on the previous level's bar if it still fits (the color
        // count can change with assist or the caregiver cap); otherwise draw a fresh one.
        let previous = self.session?.palette
        var palette = nextPalette ?? CandyArt.Palette.random(level: level, count: config.colorCount, avoiding: previous)
        if palette.types.count != config.colorCount {
            palette = CandyArt.Palette.random(level: level, count: config.colorCount, avoiding: previous)
        }
        let session = GameSession(config: config, palette: palette, bonus: palette.newType(comparedTo: previous),
                                  swipeDemo: !progress.hasEverSwiped)
        let next = LevelConfig(level: level + 1,
                               assist: DebugFlags.assist ?? progress.assist,
                               maxColors: Settings.shared.maxColors,
                               maxRows: boardMaxRows)
        let upcoming = CandyArt.Palette.random(level: next.level, count: next.colorCount, avoiding: palette)
        nextPalette = upcoming
        session.nextCandy = CandyArt.Preview(type: upcoming.newType(comparedTo: palette))
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
        nextPalette = nil
        screen = .play
    }

    /// Called when the Good Job screen finishes (timeout or tap). Guarded so a tap and the
    /// timer firing together cannot skip a level.
    func continueAfterGoodJob() {
        guard !advancing, let finished = session?.config.level else { return }
        advancing = true
        _ = finished
        Task {
            if sessionIsOver {
                screen = .goodNight
                return
            }
            if isAtLock {
                // End of the free part: back to the Play screen, where the button shows a lock
                // until a caregiver unlocks all levels or starts again from level 1.
                session = nil
                screen = .play
                return
            }
            startLevel(DebugFlags.startLevel.map { max($0, progress.currentLevel) } ?? progress.currentLevel)
            screen = .level
        }
    }
}
