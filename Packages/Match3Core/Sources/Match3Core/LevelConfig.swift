import Foundation

/// Everything that defines a level. Derived deterministically from the level number so the
/// game is endless and needs no level data files.
public struct LevelConfig: Hashable, Sendable {
    public let level: Int
    public let rows: Int
    public let cols: Int
    public let shape: BoardShape
    public let colorCount: Int
    /// Number of match groups the player must make to finish the level.
    public let goalMatches: Int
    public let seed: UInt64

    public static let maxRows = 8
    public static let maxCols = 8
    public static let maxColors = TileColor.maxCount
    public static let maxGoal = 20

    public init(level: Int) {
        precondition(level >= 1)
        self.level = level

        let (rows, cols, shape) = LevelConfig.geometry(for: level)
        self.rows = rows
        self.cols = cols
        self.shape = shape
        self.colorCount = LevelConfig.colorCount(for: level)
        self.goalMatches = LevelConfig.goal(for: level)
        self.seed = 0x5EED_0000 &+ UInt64(level) &* 7919

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

    private static let laterSizes: [(Int, Int)] = [
        (6, 6), (7, 6), (6, 7), (7, 7), (8, 6), (6, 8), (8, 7), (7, 8), (8, 8),
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

    private static func colorCount(for level: Int) -> Int {
        switch level {
        case 1...7: return 3
        case 8...16: return 4
        case 17...30: return 5
        default: return maxColors
        }
    }

    private static func goal(for level: Int) -> Int {
        // 3 at level 1, +1 every 2 levels, capped.
        min(maxGoal, 3 + (level - 1) / 2)
    }
}
