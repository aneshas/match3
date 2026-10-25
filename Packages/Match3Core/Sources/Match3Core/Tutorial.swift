import Foundation

/// A swipe the game wants the player to make: `from` is dragged onto `to`.
public struct PlantedMove: Hashable, Sendable {
    public let from: Position
    public let to: Position

    public init(from: Position, to: Position) {
        self.from = from
        self.to = to
    }

    /// The same two cells in either order.
    public func matches(_ a: Position, _ b: Position) -> Bool {
        (a == from && b == to) || (a == to && b == from)
    }
}

/// Lessons for the special candies: on the level a new special arrives, the board is
/// rewritten so one swipe earns it and, once it sits on the board, one more swipe sets
/// it off. The game shows each swipe with the hand and accepts nothing else meanwhile.
extension Board {
    /// One lesson layout: the cells of the match that will form (`group`), which of them
    /// holds the odd candy out (`gap`), and the cell next to the gap holding the candy
    /// that completes the match when swiped in (`key`). All relative to an origin.
    private struct SpawnPattern {
        let group: [Position]
        let gap: Position
        let key: Position

        /// The eight rotations and reflections of the pattern.
        var variants: [SpawnPattern] {
            var out: [SpawnPattern] = []
            for flip in [false, true] {
                for rot in 0..<4 {
                    func t(_ p: Position) -> Position {
                        var (r, c) = (p.row, p.col)
                        if flip { c = -c }
                        for _ in 0..<rot { (r, c) = (c, -r) }
                        return Position(row: r, col: c)
                    }
                    out.append(SpawnPattern(group: group.map(t), gap: t(gap), key: t(key)))
                }
            }
            return out
        }

        static func line(_ length: Int) -> SpawnPattern {
            let mid = length / 2
            return SpawnPattern(group: (0..<length).map { Position(row: 0, col: $0) },
                                gap: Position(row: 0, col: mid), key: Position(row: 1, col: mid))
        }

        /// A T: a bar of `bar` cells with a stem of `stem` hanging from its second cell. The
        /// gap is where bar and stem meet, so nothing matches before the swipe.
        static func tee(bar: Int, stem: Int) -> SpawnPattern {
            let group = (0..<bar).map { Position(row: 0, col: $0) } + (1...stem).map { Position(row: $0, col: 1) }
            return SpawnPattern(group: group, gap: Position(row: 0, col: 1), key: Position(row: -1, col: 1))
        }
    }

    private static func spawnPatterns(for kind: PowerKind) -> [SpawnPattern] {
        switch kind {
        case .wrapped: return [.line(4)]
        case .striped: return [.line(5)]
        case .rainbow: return [.tee(bar: 3, stem: 2)]
        case .bomb: return [.line(6), .tee(bar: 4, stem: 2)]
        }
    }

    /// Rewrites part of the board so that one swipe makes a match that earns `kind`, and
    /// nothing matches before it. Tile ids are kept so the change can be animated. Returns
    /// nil when no placement fits this board (then there is simply no lesson).
    public mutating func plantPowerSpawn(_ kind: PowerKind) -> PlantedMove? {
        let center = (Double(rows - 1) / 2, Double(cols - 1) / 2)
        var placements: [(SpawnPattern, Position)] = []
        for pattern in Board.spawnPatterns(for: kind) {
            for v in pattern.variants {
                for r in 0..<rows {
                    for c in 0..<cols {
                        let origin = Position(row: r, col: c)
                        let cells = v.group + [v.key]
                        guard cells.allSatisfy({ isPlayable(Position(row: $0.row + origin.row, col: $0.col + origin.col)) }) else { continue }
                        placements.append((v, origin))
                    }
                }
            }
        }
        // Central placements first, so the lesson happens where the player looks.
        func distance(_ v: SpawnPattern, _ o: Position) -> Double {
            let rs = v.group.map { Double($0.row + o.row) }, cs = v.group.map { Double($0.col + o.col) }
            let mr = rs.reduce(0, +) / Double(rs.count), mc = cs.reduce(0, +) / Double(cs.count)
            return abs(mr - center.0) + abs(mc - center.1)
        }
        placements.sort { distance($0.0, $0.1) < distance($1.0, $1.1) }

        let colors = (0..<colorCount).map(TileColor.init)
        for (v, o) in placements {
            func abs(_ p: Position) -> Position { Position(row: p.row + o.row, col: p.col + o.col) }
            let group = Set(v.group.map(abs)), gap = abs(v.gap), key = abs(v.key)
            for a in colors {
                for b in colors where b != a {
                    let saved = cells
                    for p in group where p != gap { recolor(p, a) }
                    recolor(gap, b)
                    recolor(key, a)
                    if settle(keeping: group.union([key])) {
                        var copy = self
                        copy.swap(key, gap)
                        let matches = copy.findMatches()
                        if matches.count == 1, matches[0].positions == group,
                           matches[0].earnedPower(allowed: [kind])?.kind == kind {
                            return PlantedMove(from: key, to: gap)
                        }
                    }
                    cells = saved
                }
            }
        }
        return nil
    }

    /// Rearranges the candies around the special at `at` so that swiping it onto a neighbor
    /// lines it up with two of its own color. For a rainbow any neighbor will do, so
    /// nothing is rewritten. Returns nil if the special has no room.
    public mutating func plantPowerTrigger(at s: Position) -> PlantedMove? {
        guard let special = tile(at: s), special.power != .none else { return nil }
        let neighbors = Direction.allCases.map { s.offset($0) }.filter { isPlayable($0) && tile(at: $0) != nil }
        if special.power.isRainbow {
            return neighbors.first.map { PlantedMove(from: s, to: $0) }
        }
        let a = special.color
        let colors = (0..<colorCount).map(TileColor.init)
        for n in neighbors where tile(at: n)?.power == Power.none {
            let dr = n.row - s.row, dc = n.col - s.col
            // Two layouts: the special lands between two of its color (across the swipe), or
            // ahead of two of its color (along the swipe).
            let across = [Position(row: n.row + dc, col: n.col + dr), Position(row: n.row - dc, col: n.col - dr)]
            let along = [Position(row: n.row + dr, col: n.col + dc), Position(row: n.row + 2 * dr, col: n.col + 2 * dc)]
            for partners in [across, along] {
                guard partners.allSatisfy({ isPlayable($0) && tile(at: $0)?.power == Power.none }) else { continue }
                for b in colors where b != a {
                    let saved = cells
                    for p in partners { recolor(p, a) }
                    recolor(n, b)
                    if settle(keeping: Set(partners + [n, s])) {
                        var copy = self
                        copy.swap(s, n)
                        if copy.findMatches().contains(where: { $0.positions.contains(n) }) {
                            return PlantedMove(from: s, to: n)
                        }
                    }
                    cells = saved
                }
            }
        }
        return nil
    }

    /// Two specials side by side near the middle of the board, for the combo lesson.
    public mutating func plantCombo() -> PlantedMove? {
        let center = Position(row: rows / 2, col: cols / 2)
        var pairs: [(Position, Position)] = []
        for p in allPositions {
            for d in [Direction.right, .down] {
                let q = p.offset(d)
                guard isPlayable(q), tile(at: p) != nil, tile(at: q) != nil else { continue }
                pairs.append((p, q))
            }
        }
        pairs.sort {
            (Swift.abs($0.0.row - center.row) + Swift.abs($0.0.col - center.col)) <
            (Swift.abs($1.0.row - center.row) + Swift.abs($1.0.col - center.col))
        }
        guard let (p, q) = pairs.first else { return nil }
        setPower(.striped(p.row == q.row ? .vertical : .horizontal), at: p)
        setPower(.wrapped, at: q)
        return PlantedMove(from: p, to: q)
    }

    /// The position of the first special candy of `kind` on the board, if any.
    public func position(ofPower kind: PowerKind) -> Position? {
        allPositions.first { tile(at: $0)?.power.kind == kind }
    }

    /// Recolors every matching candy outside `keep` until nothing matches. False if the
    /// board would not settle (then the caller restores what it had).
    private mutating func settle(keeping keep: Set<Position>) -> Bool {
        for _ in 0..<40 {
            let matched = Set(findMatches().flatMap { $0.positions }).subtracting(keep)
            if matched.isEmpty { return findMatches().isEmpty }
            for p in matched.sorted(by: { ($0.row, $0.col) < ($1.row, $1.col) }) {
                recolor(p, colorWithoutMatch(at: p))
            }
        }
        return false
    }
}
