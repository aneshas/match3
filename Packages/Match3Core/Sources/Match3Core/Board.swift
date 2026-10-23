import Foundation

/// A group of positions removed together as one match (3+ in a line; L/T shapes merge).
public struct MatchGroup: Hashable, Sendable {
    public let positions: Set<Position>
    public let color: TileColor
}

/// A tile that fell from one cell to another during gravity.
public struct TileFall: Hashable, Sendable {
    public let tileID: UUID
    public let from: Position
    public let to: Position
}

/// A tile that entered the board from above during refill. `rowsAbove` is how many cells
/// above its column's top it conceptually started, so the UI can animate the drop.
public struct TileSpawn: Hashable, Sendable {
    public let tile: Tile
    public let at: Position
    public let rowsAbove: Int
}

public struct GravityResult: Sendable {
    public let falls: [TileFall]
    public let spawns: [TileSpawn]
}

public struct Board: Sendable {
    public let rows: Int
    public let cols: Int
    public let shape: BoardShape
    public let colorCount: Int
    public let mask: [[Bool]]
    public internal(set) var cells: [[Tile?]]
    private var rng: SeededRandom

    // MARK: - Creation

    /// Creates a board with no pre-existing matches and at least one valid move.
    public init(rows: Int, cols: Int, shape: BoardShape, colorCount: Int, seed: UInt64) {
        precondition(rows >= 3 && cols >= 3, "board too small")
        precondition(colorCount >= 3 && colorCount <= TileColor.maxCount, "colorCount out of range")
        let mask = shape.mask(rows: rows, cols: cols)
        precondition(BoardShape.columnsAreContiguous(mask), "shape breaks column contiguity")

        self.rows = rows
        self.cols = cols
        self.shape = shape
        self.colorCount = colorCount
        self.mask = mask
        self.cells = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        self.rng = SeededRandom(seed: seed)

        fillFresh()
        var attempts = 0
        while !hasAnyMove && attempts < 200 {
            fillFresh()
            attempts += 1
        }
    }

    /// Fills every playable cell with a new tile, never creating a match.
    private mutating func fillFresh() {
        for r in 0..<rows {
            for c in 0..<cols {
                guard mask[r][c] else { cells[r][c] = nil; continue }
                cells[r][c] = Tile(color: randomColorAvoidingMatch(row: r, col: c))
            }
        }
    }

    /// Picks a color that does not complete a run of 3 with the two tiles above or to the left.
    private mutating func randomColorAvoidingMatch(row: Int, col: Int) -> TileColor {
        var banned = Set<TileColor>()
        if row >= 2, let a = cells[row - 1][col], let b = cells[row - 2][col], a.color == b.color {
            banned.insert(a.color)
        }
        if col >= 2, let a = cells[row][col - 1], let b = cells[row][col - 2], a.color == b.color {
            banned.insert(a.color)
        }
        var candidates = (0..<colorCount).map(TileColor.init).filter { !banned.contains($0) }
        if candidates.isEmpty { candidates = (0..<colorCount).map(TileColor.init) }
        return candidates[Int(rng.next() % UInt64(candidates.count))]
    }

    // MARK: - Access

    public var allPositions: [Position] {
        var out: [Position] = []
        for r in 0..<rows { for c in 0..<cols where mask[r][c] { out.append(Position(row: r, col: c)) } }
        return out
    }

    public var tiles: [(tile: Tile, position: Position)] {
        allPositions.compactMap { p in cells[p.row][p.col].map { ($0, p) } }
    }

    public func isInside(_ p: Position) -> Bool {
        p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols
    }

    public func isPlayable(_ p: Position) -> Bool {
        isInside(p) && mask[p.row][p.col]
    }

    public func tile(at p: Position) -> Tile? {
        guard isPlayable(p) else { return nil }
        return cells[p.row][p.col]
    }

    public func position(of tileID: UUID) -> Position? {
        for p in allPositions where cells[p.row][p.col]?.id == tileID { return p }
        return nil
    }

    // MARK: - Swapping

    public func canSwap(_ a: Position, _ b: Position) -> Bool {
        isPlayable(a) && isPlayable(b) && a.isAdjacent(to: b) && tile(at: a) != nil && tile(at: b) != nil
    }

    /// Swaps two tiles unconditionally (caller checks `canSwap`).
    public mutating func swap(_ a: Position, _ b: Position) {
        let t = cells[a.row][a.col]
        cells[a.row][a.col] = cells[b.row][b.col]
        cells[b.row][b.col] = t
    }

    /// True if swapping `a` and `b` would produce at least one match.
    public func swapCreatesMatch(_ a: Position, _ b: Position) -> Bool {
        guard canSwap(a, b) else { return false }
        var copy = self
        copy.swap(a, b)
        return copy.hasMatch(at: a) || copy.hasMatch(at: b)
    }

    // MARK: - Matching

    /// Whether the tile at `p` is part of a horizontal or vertical run of 3+.
    public func hasMatch(at p: Position) -> Bool {
        guard let t = tile(at: p) else { return false }
        return runLength(from: p, color: t.color, horizontal: true) >= 3
            || runLength(from: p, color: t.color, horizontal: false) >= 3
    }

    private func runLength(from p: Position, color: TileColor, horizontal: Bool) -> Int {
        var count = 1
        for dir: [Direction] in [[horizontal ? .left : .up], [horizontal ? .right : .down]] {
            var q = p.offset(dir[0])
            while let t = tile(at: q), t.color == color {
                count += 1
                q = q.offset(dir[0])
            }
        }
        return count
    }

    /// All current matches, with overlapping horizontal/vertical runs merged into one group.
    public func findMatches() -> [MatchGroup] {
        var runs: [(Set<Position>, TileColor)] = []

        // Horizontal runs.
        for r in 0..<rows {
            var c = 0
            while c < cols {
                let start = Position(row: r, col: c)
                guard let t = tile(at: start) else { c += 1; continue }
                var end = c
                while end + 1 < cols, let n = tile(at: Position(row: r, col: end + 1)), n.color == t.color { end += 1 }
                if end - c + 1 >= 3 {
                    runs.append((Set((c...end).map { Position(row: r, col: $0) }), t.color))
                }
                c = end + 1
            }
        }
        // Vertical runs.
        for c in 0..<cols {
            var r = 0
            while r < rows {
                let start = Position(row: r, col: c)
                guard let t = tile(at: start) else { r += 1; continue }
                var end = r
                while end + 1 < rows, let n = tile(at: Position(row: end + 1, col: c)), n.color == t.color { end += 1 }
                if end - r + 1 >= 3 {
                    runs.append((Set((r...end).map { Position(row: $0, col: c) }), t.color))
                }
                r = end + 1
            }
        }

        // Merge runs that share a cell (L and T shapes become one group).
        var groups: [(Set<Position>, TileColor)] = []
        for run in runs {
            var merged = run
            var remaining: [(Set<Position>, TileColor)] = []
            for g in groups {
                if g.1 == merged.1, !g.0.isDisjoint(with: merged.0) {
                    merged.0.formUnion(g.0)
                } else {
                    remaining.append(g)
                }
            }
            remaining.append(merged)
            groups = remaining
        }
        return groups.map { MatchGroup(positions: $0.0, color: $0.1) }
    }

    /// Removes the tiles at the given positions.
    public mutating func remove(_ positions: Set<Position>) {
        for p in positions where isPlayable(p) { cells[p.row][p.col] = nil }
    }

    // MARK: - Gravity

    /// Drops tiles down within each column and spawns new tiles at the top to fill gaps.
    public mutating func applyGravityAndRefill() -> GravityResult {
        var falls: [TileFall] = []
        var spawns: [TileSpawn] = []

        for c in 0..<cols {
            let playableRows = (0..<rows).filter { mask[$0][c] }
            guard let top = playableRows.first, let bottom = playableRows.last else { continue }

            // Existing tiles in this column, top to bottom.
            var stack: [(Tile, Int)] = []
            for r in top...bottom { if let t = cells[r][c] { stack.append((t, r)) } }

            // Place them from the bottom up.
            var writeRow = bottom
            for (t, fromRow) in stack.reversed() {
                if fromRow != writeRow {
                    falls.append(TileFall(tileID: t.id, from: Position(row: fromRow, col: c), to: Position(row: writeRow, col: c)))
                }
                cells[writeRow][c] = t
                writeRow -= 1
            }

            // Fill what is left (top of column) with new tiles.
            let emptyCount = writeRow - top + 1
            if emptyCount > 0 {
                for r in top...writeRow {
                    let tile = Tile(color: TileColor(Int(rng.next() % UInt64(colorCount))))
                    cells[r][c] = tile
                    spawns.append(TileSpawn(tile: tile, at: Position(row: r, col: c), rowsAbove: writeRow - r + 1))
                }
            }
        }
        return GravityResult(falls: falls, spawns: spawns)
    }

    // MARK: - Moves

    /// Finds any swap that creates a match, or nil if the board is stuck.
    public func findAnyMove() -> (Position, Position)? {
        for p in allPositions {
            for d in [Direction.right, .down] {
                let q = p.offset(d)
                if swapCreatesMatch(p, q) { return (p, q) }
            }
        }
        return nil
    }

    public var hasAnyMove: Bool { findAnyMove() != nil }

    /// Re-colors all tiles (keeping their ids) until there is no match and at least one move.
    public mutating func shuffle() {
        var attempts = 0
        repeat {
            for r in 0..<rows {
                for c in 0..<cols {
                    guard let old = cells[r][c] else { continue }
                    cells[r][c] = nil
                    cells[r][c] = Tile(id: old.id, color: randomColorAvoidingMatch(row: r, col: c))
                }
            }
            attempts += 1
        } while (!findMatches().isEmpty || !hasAnyMove) && attempts < 200
    }
}
