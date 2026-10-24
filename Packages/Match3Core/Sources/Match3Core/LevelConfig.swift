import Foundation

/// Everything that defines a level. Derived deterministically from the level number so the
/// game is endless and needs no level data files.
public struct LevelConfig: Hashable, Sendable {
    public let level: Int
    /// Adaptive-difficulty softening applied to this level (0 = none). See `AssistPolicy`.
    public let assist: Int
    public let rows: Int
    public let cols: Int
    public let shape: BoardShape
    public let colorCount: Int
    /// Number of successful swaps the player must make to finish the level. Cascades do
    /// not count: they are a bonus, not the way to finish.
    public let goalMatches: Int
    public let seed: UInt64

    /// Never wider than 7 columns: on a phone the candies get too small beyond that. Boards
    /// may be taller than wide (up to 9 rows) because phones have the room vertically;
    /// the app passes a `maxRows` it can show at the 7-column candy size.
    public static let maxRows = 9
    public static let maxCols = 7
    public static let maxColors = TileColor.maxCount
    public static let maxGoal = 15

    /// - Parameters:
    ///   - assist: adaptive softening, see `AssistPolicy`.
    ///   - maxColors: caregiver cap on colors (3...6).
    ///   - variant: changes the board layout without changing anything else (replays).
    ///   - maxRows: how many rows the screen can show at the 7-column candy size (4...9).
    public init(level: Int, assist: Int = 0, maxColors: Int = TileColor.maxCount, variant: Int = 0,
                maxRows: Int = LevelConfig.maxRows) {
        precondition(level >= 1)
        let assist = max(0, min(AssistPolicy.maxAssist, assist))
        let maxColors = max(3, min(TileColor.maxCount, maxColors))
        let maxRows = max(4, min(LevelConfig.maxRows, maxRows))
        self.level = level
        self.assist = assist

        var (rows, cols, shape) = LevelConfig.geometry(for: level)
        if assist >= 2 {
            // Trim one row and one column.
            rows = max(4, rows - 1)
            cols = max(4, cols - 1)
        }
        rows = min(rows, maxRows)
        // Make sure the shape still works at the final size; otherwise soften it.
        if !(shape.fits(rows: rows, cols: cols) && LevelConfig.isValid(rows, cols, shape)) {
            shape = shape == .square ? .square : .roundedCorners
            if !(shape.fits(rows: rows, cols: cols) && LevelConfig.isValid(rows, cols, shape)) { shape = .square }
        }
        self.rows = rows
        self.cols = cols
        self.shape = shape
        self.colorCount = min(maxColors, max(3, LevelConfig.colorCount(for: level) - assist))
        self.goalMatches = max(3, LevelConfig.goal(for: level) - assist)
        self.seed = 0x5EED_0000 &+ UInt64(level) &* 7919 &+ UInt64(max(0, variant)) &* 104_729

        let mask = shape.mask(rows: rows, cols: cols)
        assert(BoardShape.columnsAreContiguous(mask))
        assert(mask.flatMap { $0 }.filter { $0 }.count >= LevelConfig.minPlayableCells)
    }

    public func makeBoard() -> Board {
        Board(rows: rows, cols: cols, shape: shape, colorCount: colorCount, seed: seed)
    }

    // MARK: - Progression tables

    /// Fewest playable cells a board may have. Small early boards are the point.
    public static let minPlayableCells = 12

    /// The first levels are hand-picked: tiny, then gently non-square, then the first shapes.
    private static let openingLevels: [(Int, Int, BoardShape)] = [
        (4, 4, .square),          // 1
        (5, 4, .square),          // 2  tall
        (4, 5, .square),          // 3  wide
        (5, 5, .roundedCorners),  // 4
        (6, 5, .roundedCorners),  // 5  tall
        (6, 6, .diamond),         // 6
        (5, 6, .roundedCorners),  // 7  wide
        (6, 6, .triangle),        // 8
        (7, 7, .cross),           // 9
        (7, 7, .heart),           // 10
    ]

    /// (rows, cols). Columns stop at 7; rows keep growing so later boards are tall.
    private static let laterSizes: [(Int, Int)] = [
        (6, 6), (7, 6), (6, 7), (7, 7), (8, 6), (8, 7), (9, 6), (9, 7),
    ]
    private static let laterShapes: [BoardShape] = [
        .square, .roundedCorners, .heart, .cross, .diamond, .triangle, .circle, .octagon,
    ]

    private static func geometry(for level: Int) -> (Int, Int, BoardShape) {
        if level <= openingLevels.count {
            return openingLevels[level - 1]
        }
        let step = level - openingLevels.count - 1
        let (r, c) = laterSizes[min(step / 3, laterSizes.count - 1)]
        // Walk the shape cycle until one fits this size, so small boards never get a
        // degenerate shape and big boards still see every shape.
        for offset in 0..<laterShapes.count {
            let shape = laterShapes[(step + offset) % laterShapes.count]
            if shape.fits(rows: r, cols: c), isValid(r, c, shape) { return (r, c, shape) }
        }
        return (r, c, .square)
    }

    private static func isValid(_ r: Int, _ c: Int, _ shape: BoardShape) -> Bool {
        let mask = shape.mask(rows: r, cols: c)
        let playable = mask.flatMap { $0 }.filter { $0 }.count
        return playable >= minPlayableCells && BoardShape.columnsAreContiguous(mask)
    }

    /// Colors arrive slowly: size and shape carry the difficulty first. Telling candies
    /// apart is the hard part for this audience, so the 4th color waits until level 13.
    private static func colorCount(for level: Int) -> Int {
        switch level {
        case 1...12: return 3
        case 13...24: return 4
        case 25...40: return 5
        default: return maxColors
        }
    }

    private static func goal(for level: Int) -> Int {
        // The goal is the number of successful swipes: 3 at level 1, about +2 every 3 levels,
        // capped at 15 (around level 19).
        min(maxGoal, 3 + (level - 1) * 2 / 3)
    }
}
