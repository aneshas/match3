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

    func markCompleted(_ level: Int) {
        if level >= currentLevel {
            defaults.set(level + 1, forKey: key)
        }
    }
}
