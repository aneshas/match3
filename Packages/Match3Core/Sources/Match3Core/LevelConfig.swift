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
    public static let maxGoal = 48

    /// The level each special candy first appears on, and when two specials may be swiped
    /// into each other. One new thing every tier, nothing before level 10.
    public static let powerUnlocks: [PowerKind: Int] = [.wrapped: 10, .striped: 15, .rainbow: 30, .bomb: 40]
    public static let combosFromLevel = 50

    public static func unlockedPowers(level: Int) -> Set<PowerKind> {
        Set(powerUnlocks.filter { level >= $0.value }.map(\.key))
    }

    public static func combosUnlocked(level: Int) -> Bool { level >= combosFromLevel }

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
        // Masked shapes take a bigger grid (within the screen's rows) so they stay as full
        // of candies as the rectangle they replace.
        (rows, cols) = LevelConfig.grown(rows, cols, shape, maxRows: maxRows)
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

    /// The opening: ten sizes over fifty levels, each lasting four to seven levels
    /// (rows, cols, first level at which the size appears). Sizes never jump by more than
    /// one row or column.
    private static let openingSizes: [(rows: Int, cols: Int, from: Int)] = [
        (4, 4, 1), (4, 5, 5), (5, 4, 9), (5, 5, 13), (6, 5, 19),
        (5, 6, 24), (6, 6, 29), (7, 6, 36), (6, 7, 41), (7, 7, 46),
    ]
    public static let openingLength = 50

    /// After the opening the size changes every five levels, cycling through these
    /// (rows, cols). Columns stop at 7; rows grow so later boards are tall.
    private static let laterSizes: [(Int, Int)] = [
        (7, 7), (8, 6), (8, 7), (9, 6), (9, 7), (8, 7), (8, 6),
    ]

    /// Level at which each shape may first appear (if the size allows it). A shape shows
    /// on its unlock level, then the unlocked shapes take turns.
    private static let shapeUnlocks: [(BoardShape, Int)] = [
        (.square, 1), (.roundedCorners, 13), (.diamond, 29), (.triangle, 32),
        (.cross, 46), (.heart, 48), (.octagon, 51), (.circle, 56),
    ]

    private static func geometry(for level: Int) -> (Int, Int, BoardShape) {
        let r: Int, c: Int
        if level <= openingLength {
            let size = openingSizes.last { $0.from <= level }!
            (r, c) = (size.rows, size.cols)
        } else {
            let step = (level - openingLength - 1) / 5
            (r, c) = laterSizes[step % laterSizes.count]
        }
        let unlocked = shapeUnlocks.filter { $0.1 <= level && $0.0.fits(rows: r, cols: c) && isValid(r, c, $0.0) }
        guard let newest = unlocked.max(by: { $0.1 < $1.1 }) else { return (r, c, .square) }
        // Newest shape first, then the older ones in turn: an unlock shows right away and
        // no shape repeats back to back.
        let order = unlocked.sorted { $0.1 > $1.1 }.map { $0.0 }
        return (r, c, order[(level - newest.1) % order.count])
    }

    /// A masked shape gets a bigger grid so it keeps about as many candies as the full
    /// rectangle it replaces (a diamond or triangle cut away up to half): rows first,
    /// which costs nothing on a phone, up to what the screen shows, then columns up to 7.
    static func grown(_ r: Int, _ c: Int, _ shape: BoardShape, maxRows: Int = LevelConfig.maxRows) -> (Int, Int) {
        let target = Int((Double(r * c) * 0.85).rounded(.up))
        func cells(_ r: Int, _ c: Int) -> Int { shape.mask(rows: r, cols: c).flatMap { $0 }.filter { $0 }.count }
        var (gr, gc) = (r, c)
        while cells(gr, gc) < target {
            if gr < maxRows { gr += 1 } else if gc < maxCols { gc += 1 } else { break }
        }
        return (gr, gc)
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
        // The goal is in steps (one per plain swipe): 12 at level 1, about +4 every 3 levels,
        // capped at 48 (around level 28).
        min(maxGoal, 12 + (level - 1) * 4 / 3)
    }
}
