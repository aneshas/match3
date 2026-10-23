import Foundation
import Observation

/// Everything we persist about the player: current level (endless, never decreases on its
/// own), adaptive assist, whether they ever swiped, and a log of finished levels for the
/// caregiver stats. Observable so screens update the moment a caregiver resets or unlocks.

@Observable
final class Progress {
    private let defaults: UserDefaults
    private let levelKey = "currentLevel"
    private let assistKey = "assist"
    private let swipedKey = "hasEverSwiped"
    private let logKey = "completionLog"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currentLevel = max(1, defaults.integer(forKey: levelKey))
        assist = defaults.integer(forKey: assistKey)
        hasEverSwiped = defaults.bool(forKey: swipedKey)
        completionLog = defaults.array(forKey: logKey) as? [Date] ?? []
    }

    private(set) var currentLevel: Int { didSet { defaults.set(currentLevel, forKey: levelKey) } }

    /// Adaptive-difficulty softening for the next level (0...3). See `AssistPolicy`.
    var assist: Int { didSet { defaults.set(assist, forKey: assistKey) } }

    /// True once the player has made one successful swap, ever. Until then the swipe demo
    /// (animated hand) runs on each level.
    private(set) var hasEverSwiped: Bool { didSet { defaults.set(hasEverSwiped, forKey: swipedKey) } }

    /// Timestamps of finished levels, newest last, capped. Only used for caregiver stats.
    private(set) var completionLog: [Date] { didSet { defaults.set(completionLog, forKey: logKey) } }

    func levelsFinished(since date: Date) -> Int {
        completionLog.filter { $0 >= date }.count
    }

    func markSwiped() { hasEverSwiped = true }
    func forgetSwipe() { hasEverSwiped = false }

    func markCompleted(_ level: Int) {
        if level >= currentLevel { currentLevel = level + 1 }
        var log = completionLog
        log.append(Date())
        if log.count > 1000 { log.removeFirst(log.count - 1000) }
        completionLog = log
    }

    /// Caregiver "start again": level 1, empty jar, assist off. Keeps "has ever swiped".
    func reset() {
        currentLevel = 1
        completionLog = []
        assist = 0
    }
}
