import Foundation

/// What happened during one level, as far as difficulty is concerned.
public struct LevelStats: Hashable, Sendable {
    public var matches: Int = 0
    public var invalidSwaps: Int = 0
    public var hintsShown: Int = 0
    /// Seconds from the first moment the player could move until the goal was reached.
    public var seconds: Double = 0

    public init(matches: Int = 0, invalidSwaps: Int = 0, hintsShown: Int = 0, seconds: Double = 0) {
        self.matches = matches
        self.invalidSwaps = invalidSwaps
        self.hintsShown = hintsShown
        self.seconds = seconds
    }
}

/// Quiet adaptive difficulty. `assist` is 0 (normal) to `maxAssist`; each step removes a
/// color, trims the board and lowers the goal for the next level. Nothing is ever shown
/// to the player, and assist only ever softens the normal progression.
public enum AssistPolicy {
    public static let maxAssist = 3

    /// Returns the assist level to use for the next level.
    public static func next(after stats: LevelStats, current: Int) -> Int {
        let matches = max(1, stats.matches)
        let invalidPerMatch = Double(stats.invalidSwaps) / Double(matches)
        let secondsPerMatch = stats.seconds / Double(matches)

        let struggled = invalidPerMatch >= 1.5 || stats.hintsShown >= 3 || secondsPerMatch >= 25
        let breezed = invalidPerMatch <= 0.34 && stats.hintsShown == 0 && secondsPerMatch <= 8

        if struggled { return min(maxAssist, current + 1) }
        if breezed { return max(0, current - 1) }
        return current
    }
}
