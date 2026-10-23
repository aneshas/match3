import Foundation

/// The only thing we persist: which level the player is on. Endless, never decreases.
final class Progress {
    private let defaults: UserDefaults
    private let key = "currentLevel"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentLevel: Int {
        max(1, defaults.integer(forKey: key))
    }

    private let assistKey = "assist"

    /// Adaptive-difficulty softening for the next level (0...3). See `AssistPolicy`.
    var assist: Int {
        get { defaults.integer(forKey: assistKey) }
        set { defaults.set(newValue, forKey: assistKey) }
    }

    private let swipedKey = "hasEverSwiped"

    /// True once the player has made one successful swap, ever. Until then the swipe demo
    /// (animated hand) runs on each level.
    var hasEverSwiped: Bool { defaults.bool(forKey: swipedKey) }

    func markSwiped() {
        defaults.set(true, forKey: swipedKey)
    }

    func forgetSwipe() {
        defaults.removeObject(forKey: swipedKey)
    }

    func markCompleted(_ level: Int) {
        if level >= currentLevel {
            defaults.set(level + 1, forKey: key)
        }
    }
}
