import Foundation

/// A group of positions removed together as one match (3+ in a line; L/T shapes merge).
public struct MatchGroup: Hashable, Sendable {
    public let positions: Set<Position>
    public let color: TileColor

    /// Longest straight run inside the group and its axis.
    public var longestRun: (length: Int, axis: LineAxis) {
        var best = (length: 1, axis: LineAxis.horizontal)
        for p in positions {
            if !positions.contains(Position(row: p.row, col: p.col - 1)) {
                var n = 1
                while positions.contains(Position(row: p.row, col: p.col + n)) { n += 1 }
                if n > best.length { best = (n, .horizontal) }
            }
            if !positions.contains(Position(row: p.row - 1, col: p.col)) {
                var n = 1
                while positions.contains(Position(row: p.row + n, col: p.col)) { n += 1 }
                if n > best.length { best = (n, .vertical) }
            }
        }
        return best
    }

    /// True for L and T shapes: the group is not one straight line.
    public var isBent: Bool {
        let rows = Set(positions.map(\.row)), cols = Set(positions.map(\.col))
        return rows.count > 1 && cols.count > 1
    }

    /// Which special candy this match earns when every kind is available: six or more in
    /// any shape give a bomb, an L or T of five or more a rainbow, five in a line a striped
    /// candy along that line, four a wrapped candy, three nothing.
    public var earnedPower: Power? { earnedPower(allowed: Set(PowerKind.allCases)) }

    /// The best special this match earns among the `allowed` kinds: a match too good for
    /// the kinds unlocked so far falls back to the next one down, so a five-match before
    /// striped candies exist still earns a wrapped one.
    public func earnedPower(allowed: Set<PowerKind>) -> Power? {
        let run = longestRun
        if positions.count >= 6, allowed.contains(.bomb) { return .bomb }
        if positions.count >= 5, isBent, allowed.contains(.rainbow) { return .rainbow }
        if run.length >= 5, allowed.contains(.striped) { return .striped(run.axis) }
        if positions.count >= 4, allowed.contains(.wrapped) { return .wrapped }
        return nil
    }
}

/// What swiping two neighbors does.
public enum SwapEffect: Hashable, Sendable {
    /// Nothing: the candies slide back.
    case none
    /// An ordinary match (possibly with specials in it).
    case match
    /// A rainbow candy at `at` (after the swap) going off on `color`.
    case rainbow(color: TileColor, at: Position)
    /// Two special candies swiped into each other; positions after the swap.
    case combo(Position, Position)
}

/// A special candy that went off while a match was cleared.
public struct PowerTrigger: Hashable, Sendable {
    public let position: Position
    public let power: Power
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
        if !hasAnyMove { plantMove() }
    }

    /// Last resort after random re-coloring kept failing (only conceivable on tiny boards
    /// with many colors): writes a guaranteed move, "A A B A" along some row or column,
    /// without creating a match. Tile ids are kept so the UI can animate the change.
    mutating func plantMove() {
        let colors = (0..<colorCount).map(TileColor.init)
        for horizontal in [true, false] {
            let lines = horizontal ? rows : cols
            let length = horizontal ? cols : rows
            for line in 0..<lines {
                for start in 0..<max(0, length - 3) {
                    let run = (start..<start + 4).map { horizontal ? Position(row: line, col: $0) : Position(row: $0, col: line) }
                    guard run.allSatisfy({ isPlayable($0) && tile(at: $0)?.power != .rainbow }) else { continue }
                    let saved = run.map { tile(at: $0) }
                    for a in colors {
                        for b in colors where b != a {
                            recolor(run[0], a); recolor(run[1], a); recolor(run[2], b); recolor(run[3], a)
                            if findMatches().isEmpty { return }
                        }
                    }
                    for (p, t) in zip(run, saved) { cells[p.row][p.col] = t }
                }
            }
        }
    }

    mutating func recolor(_ p: Position, _ color: TileColor) {
        cells[p.row][p.col] = Tile(id: cells[p.row][p.col]?.id ?? UUID(), color: color, power: cells[p.row][p.col]?.power ?? .none)
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
        if row >= 2, let a = matchColor(cells[row - 1][col]), let b = matchColor(cells[row - 2][col]), a == b {
            banned.insert(a)
        }
        if col >= 2, let a = matchColor(cells[row][col - 1]), let b = matchColor(cells[row][col - 2]), a == b {
            banned.insert(a)
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

    /// The color a tile matches by: nil for an empty cell, for a rainbow candy (which has
    /// no color and never takes part in a line) and for the wildcard (which takes part in
    /// any line, see `compatible`).
    private func matchColor(_ t: Tile?) -> TileColor? {
        guard let t, !t.power.isRainbow, !t.power.isWild else { return nil }
        return t.color
    }

    public func matchColor(at p: Position) -> TileColor? { matchColor(tile(at: p)) }

    /// Whether the tile at `p` can sit in a line of `color`: a candy of that color or the
    /// wildcard star.
    private func compatible(_ p: Position, with color: TileColor) -> Bool {
        guard let t = tile(at: p) else { return false }
        return t.power.isWild || (!t.power.isRainbow && t.color == color)
    }

    public var hasWild: Bool { allPositions.contains { tile(at: $0)?.power.isWild == true } }

    /// Plain candies that could become the wildcard without completing a line on the spot.
    public func wildSpawnCandidates() -> [Position] {
        allPositions.filter { p in
            guard let t = tile(at: p), t.power == .none else { return false }
            var copy = self
            copy.setPower(.wild, at: p)
            return !copy.hasMatch(at: p)
        }
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

    /// What swiping `a` and `b` into each other does. Two specials make a combo when
    /// `combos` is on; a rainbow goes off on the other candy's color; otherwise it is a
    /// plain match or nothing.
    public func swapEffect(_ a: Position, _ b: Position, combos: Bool) -> SwapEffect {
        guard canSwap(a, b), let ta = tile(at: a), let tb = tile(at: b) else { return .none }
        if combos, ta.power != .none, tb.power != .none { return .combo(a, b) }
        if ta.power.isRainbow, !tb.power.isRainbow { return .rainbow(color: tb.color, at: b) }
        if tb.power.isRainbow, !ta.power.isRainbow { return .rainbow(color: ta.color, at: a) }
        if ta.power.isRainbow, tb.power.isRainbow { return combos ? .combo(a, b) : .none }
        return swapCreatesMatch(a, b) ? .match : .none
    }

    public func isValidSwap(_ a: Position, _ b: Position, combos: Bool) -> Bool {
        swapEffect(a, b, combos: combos) != .none
    }

    // MARK: - Matching

    /// Whether the tile at `p` is part of a horizontal or vertical run of 3+.
    public func hasMatch(at p: Position) -> Bool {
        guard let t = tile(at: p), !t.power.isRainbow else { return false }
        // The wildcard matches in whichever color its neighbors run in.
        let colors: [TileColor] = t.power.isWild
            ? Array(Set(Direction.allCases.compactMap { matchColor(at: p.offset($0)) }))
            : [t.color]
        return colors.contains { color in
            runLength(from: p, color: color, horizontal: true) >= 3
                || runLength(from: p, color: color, horizontal: false) >= 3
        }
    }

    private func runLength(from p: Position, color: TileColor, horizontal: Bool) -> Int {
        var count = 1
        for dir: [Direction] in [[horizontal ? .left : .up], [horizontal ? .right : .down]] {
            var q = p.offset(dir[0])
            while compatible(q, with: color) {
                count += 1
                q = q.offset(dir[0])
            }
        }
        return count
    }

    /// All current matches, with overlapping horizontal/vertical runs merged into one group.
    public func findMatches() -> [MatchGroup] {
        var runs: [(Set<Position>, TileColor)] = []

        // Walk a line of cells: a run is consecutive candies of one color, where the
        // wildcard joins any run (a run that starts on it takes the next candy's color).
        func scan(_ line: [Position]) {
            var i = 0
            while i < line.count {
                guard let t = tile(at: line[i]), !t.power.isRainbow else { i += 1; continue }
                var color: TileColor? = t.power.isWild ? nil : t.color
                var end = i
                while end + 1 < line.count, let n = tile(at: line[end + 1]), !n.power.isRainbow,
                      n.power.isWild || color == nil || n.color == color {
                    if color == nil, !n.power.isWild { color = n.color }
                    end += 1
                }
                if end - i + 1 >= 3, let color {
                    runs.append((Set(line[i...end]), color))
                }
                i = end + 1
            }
        }
        for r in 0..<rows { scan((0..<cols).map { Position(row: r, col: $0) }) }
        for c in 0..<cols { scan((0..<rows).map { Position(row: $0, col: c) }) }

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

    /// Turns the tile at `p` into a special candy (or back into a plain one).
    public mutating func setPower(_ power: Power, at p: Position) {
        guard isInside(p), let t = cells[p.row][p.col] else { return }
        cells[p.row][p.col] = Tile(id: t.id, color: t.color, power: power)
    }

    /// Everything that gets cleared when `positions` are matched: the positions themselves
    /// plus whatever the special candies among them (and among what they clear, in a
    /// chain) take with them. Terminates because the set only ever grows within the board.
    public func expandedRemoval(for positions: Set<Position>) -> (removed: Set<Position>, triggered: [PowerTrigger]) {
        var removed = Set(positions.filter { tile(at: $0) != nil })
        var queue = Array(removed).sorted { ($0.row, $0.col) < ($1.row, $1.col) }
        var triggered: [PowerTrigger] = []
        var seen = Set<Position>()
        while let p = queue.popLast() {
            guard !seen.contains(p), let t = tile(at: p), t.power != .none, !t.power.isWild else { continue }
            seen.insert(p)
            triggered.append(PowerTrigger(position: p, power: t.power))
            let extra: [Position]
            switch t.power {
            case .none, .wild:
                extra = []
            case .wrapped:
                extra = (-1...1).flatMap { dr in (-1...1).map { dc in Position(row: p.row + dr, col: p.col + dc) } }
            case .striped:
                // Whole row and whole column, whichever way the stripes run.
                extra = (0..<cols).map { Position(row: p.row, col: $0) } + (0..<rows).map { Position(row: $0, col: p.col) }
            case .bomb:
                extra = (-2...2).flatMap { dr in (-2...2).map { dc in Position(row: p.row + dr, col: p.col + dc) } }
            case .rainbow:
                // Set off by another special: takes the board's most common color with it.
                extra = mostCommonColor.map { self.positions(of: $0) } ?? []
            }
            for q in extra where tile(at: q) != nil && !removed.contains(q) {
                removed.insert(q)
                queue.append(q)
            }
        }
        return (removed, triggered)
    }

    /// Every cell holding a candy that matches by `color` (rainbows have none).
    public func positions(of color: TileColor) -> [Position] {
        allPositions.filter { matchColor(at: $0) == color }
    }

    /// The color with the most candies on the board, ties broken by index.
    public var mostCommonColor: TileColor? {
        var counts: [TileColor: Int] = [:]
        for p in allPositions { if let c = matchColor(at: p) { counts[c, default: 0] += 1 } }
        return counts.max { ($0.value, -$0.key.index) < ($1.value, -$1.key.index) }?.key
    }

    /// What a rainbow candy at `at` clears when swiped onto a candy of `color`: itself and
    /// every candy of that color, plus whatever specials among them take with them.
    public func rainbowRemoval(color: TileColor, at: Position) -> (removed: Set<Position>, triggered: [PowerTrigger]) {
        var base = Set(positions(of: color))
        base.insert(at)
        return expandedRemoval(for: base)
    }

    /// What two specials swiped into each other clear (positions after the swap). Bigger
    /// than either alone: striped + wrapped takes three rows and three columns, two
    /// striped (or two bombs, or two rainbows) the whole board, wrapped + wrapped a 5x5,
    /// bomb + wrapped a 7x7, bomb + striped three rows and columns plus the 5x5, and a
    /// rainbow with anything turns every candy of the other one's color into that special
    /// and sets them all off.
    public func comboRemoval(_ a: Position, _ b: Position) -> (removed: Set<Position>, triggered: [PowerTrigger]) {
        guard let ta = tile(at: a), let tb = tile(at: b), let ka = ta.power.kind, let kb = tb.power.kind else {
            return expandedRemoval(for: [a, b])
        }
        let pair = Set([ka, kb])
        let center = b
        func area(_ radius: Int) -> [Position] {
            (-radius...radius).flatMap { dr in (-radius...radius).map { dc in Position(row: center.row + dr, col: center.col + dc) } }
        }
        func lines(_ radius: Int) -> [Position] {
            (-radius...radius).flatMap { d in
                (0..<cols).map { Position(row: center.row + d, col: $0) } + (0..<rows).map { Position(row: $0, col: center.col + d) }
            }
        }
        let whole = allPositions

        if pair.contains(.rainbow) {
            if ka == .rainbow && kb == .rainbow { return expandedRemoval(for: Set(whole)) }
            let (other, otherTile) = ka == .rainbow ? (b, tb) : (a, ta)
            var copy = self
            var base = Set(copy.positions(of: otherTile.color))
            for p in base { copy.setPower(otherTile.power, at: p) }
            base.insert(a); base.insert(b); base.insert(other)
            return copy.expandedRemoval(for: base)
        }
        let extra: [Position]
        switch (ka, kb) {
        case (.striped, .striped), (.bomb, .bomb): extra = whole
        case (.striped, .wrapped), (.wrapped, .striped): extra = lines(1)
        case (.wrapped, .wrapped): extra = area(2)
        case (.bomb, .wrapped), (.wrapped, .bomb): extra = area(3)
        case (.bomb, .striped), (.striped, .bomb): extra = lines(1) + area(2)
        default: extra = []
        }
        var base = Set(extra.filter { tile(at: $0) != nil })
        base.insert(a); base.insert(b)
        return expandedRemoval(for: base)
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

            // Fill what is left (top of column) with new tiles. Colors are chosen so the new
            // tile does not complete a line on its own: cascades should be an occasional treat,
            // not the normal way a level finishes.
            let emptyCount = writeRow - top + 1
            if emptyCount > 0 {
                for r in top...writeRow {
                    let tile = Tile(color: colorWithoutMatch(at: Position(row: r, col: c)))
                    cells[r][c] = tile
                    spawns.append(TileSpawn(tile: tile, at: Position(row: r, col: c), rowsAbove: writeRow - r + 1))
                }
            }
        }
        return GravityResult(falls: falls, spawns: spawns)
    }

    /// A random color that does not create a match at `p` given the current neighbors
    /// (falls back to any color when every color would).
    mutating func colorWithoutMatch(at p: Position) -> TileColor {
        var candidates = (0..<colorCount).map(TileColor.init)
        // Fisher-Yates with the seeded generator so results stay reproducible.
        for i in stride(from: candidates.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            candidates.swapAt(i, j)
        }
        let saved = cells[p.row][p.col]
        defer { cells[p.row][p.col] = saved }
        for color in candidates {
            cells[p.row][p.col] = Tile(color: color)
            if !hasMatch(at: p) { return color }
        }
        return candidates[0]
    }

    // MARK: - Moves

    /// Finds any swap that creates a match, or nil if the board is stuck. Specials that go
    /// off on a swipe (rainbows, combos when `combos` is on) count as moves too, after the
    /// plain matches, so hints prefer an ordinary match.
    public func findAnyMove(combos: Bool = false) -> (Position, Position)? {
        var special: (Position, Position)?
        for p in allPositions {
            for d in [Direction.right, .down] {
                let q = p.offset(d)
                switch swapEffect(p, q, combos: combos) {
                case .match: return (p, q)
                case .none: continue
                default: if special == nil { special = (p, q) }
                }
            }
        }
        return special
    }

    public var hasAnyMove: Bool { findAnyMove(combos: true) != nil }

    /// Re-colors all tiles (keeping their ids) until there is no match and at least one move.
    public mutating func shuffle() {
        var attempts = 0
        repeat {
            for r in 0..<rows {
                for c in 0..<cols {
                    guard let old = cells[r][c] else { continue }
                    cells[r][c] = nil
                    cells[r][c] = Tile(id: old.id, color: randomColorAvoidingMatch(row: r, col: c), power: old.power)
                }
            }
            attempts += 1
        } while (!findMatches().isEmpty || !hasAnyMove) && attempts < 200
        if !hasAnyMove { plantMove() }
    }
}
