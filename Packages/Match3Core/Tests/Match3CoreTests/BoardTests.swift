import XCTest
@testable import Match3Core

final class BoardTests: XCTestCase {

    private func board(_ rows: [String]) -> Board {
        // Letters map to colors a=0..f=5, '.' is a hole. Used to build exact boards for tests.
        var b = Board(rows: rows.count, cols: rows[0].count, shape: .square, colorCount: 6, seed: 1)
        b.overwrite(with: rows)
        return b
    }

    func testFreshBoardHasNoMatchesAndHasAMove() {
        for level in 1...60 {
            let b = LevelConfig(level: level).makeBoard()
            XCTAssertTrue(b.findMatches().isEmpty, "level \(level) starts with a match")
            XCTAssertTrue(b.hasAnyMove, "level \(level) starts stuck")
        }
    }

    func testHorizontalAndVerticalRuns() {
        let b = board([
            "aaab",
            "bcdb",
            "cdcb",
            "dcdd",
        ])
        let groups = b.findMatches()
        XCTAssertEqual(groups.count, 2)
        XCTAssertTrue(groups.contains { $0.positions == Set([Position(row: 0, col: 0), Position(row: 0, col: 1), Position(row: 0, col: 2)]) })
        XCTAssertTrue(groups.contains { $0.positions == Set([Position(row: 0, col: 3), Position(row: 1, col: 3), Position(row: 2, col: 3)]) })
    }

    func testLShapeMergesIntoOneGroup() {
        let b = board([
            "aaab",
            "acdb",
            "adcc",
            "dcdd",
        ])
        let groups = b.findMatches()
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].positions.count, 5)
    }

    func testSwapCreatesMatchDetection() {
        let b = board([
            "abab",
            "bacd",
            "cdab",
            "dcdc",
        ])
        // Swapping (0,1) and (1,1) makes "aaa"? Row 0 becomes "aaab" -> yes.
        XCTAssertTrue(b.swapCreatesMatch(Position(row: 0, col: 1), Position(row: 1, col: 1)))
        XCTAssertFalse(b.swapCreatesMatch(Position(row: 3, col: 0), Position(row: 3, col: 1)))
        XCTAssertFalse(b.swapCreatesMatch(Position(row: 0, col: 0), Position(row: 1, col: 1)), "diagonal is not a swap")
    }

    func testGravityFallsAndRefillsFromTop() {
        var b = board([
            "abcd",
            "bcda",
            "cdab",
            "dabc",
        ])
        let bottomLeft = b.tile(at: Position(row: 3, col: 0))!
        let topLeft = b.tile(at: Position(row: 0, col: 0))!
        b.remove([Position(row: 1, col: 0), Position(row: 2, col: 0)])
        let result = b.applyGravityAndRefill()

        XCTAssertEqual(b.tile(at: Position(row: 3, col: 0))?.id, bottomLeft.id, "untouched tile stays")
        XCTAssertEqual(b.tile(at: Position(row: 2, col: 0))?.id, topLeft.id, "top tile fell two rows")
        XCTAssertEqual(result.falls.count, 1)
        XCTAssertEqual(result.falls[0].from, Position(row: 0, col: 0))
        XCTAssertEqual(result.falls[0].to, Position(row: 2, col: 0))
        XCTAssertEqual(result.spawns.count, 2)
        XCTAssertEqual(Set(result.spawns.map { $0.at }), Set([Position(row: 0, col: 0), Position(row: 1, col: 0)]))
        XCTAssertEqual(result.spawns.first { $0.at.row == 0 }?.rowsAbove, 2)
        XCTAssertEqual(result.spawns.first { $0.at.row == 1 }?.rowsAbove, 1)
        for p in b.allPositions { XCTAssertNotNil(b.tile(at: p)) }
    }

    func testGravityRespectsShapeHoles() {
        var b = Board(rows: 6, cols: 6, shape: .roundedCorners, colorCount: 4, seed: 3)
        XCTAssertNil(b.tile(at: Position(row: 0, col: 0)), "corner is a hole")
        XCTAssertNil(b.tile(at: Position(row: 5, col: 0)), "corner is a hole")
        b.remove([Position(row: 4, col: 0)])
        let result = b.applyGravityAndRefill()
        XCTAssertNil(b.tile(at: Position(row: 5, col: 0)), "hole stays empty after gravity")
        XCTAssertEqual(result.spawns.count, 1)
        XCTAssertEqual(result.spawns[0].at, Position(row: 1, col: 0), "refill lands at the column's playable top")
        for p in b.allPositions { XCTAssertNotNil(b.tile(at: p)) }
    }

    func testShuffleKeepsIDsAndProducesPlayableBoard() {
        var b = board([
            "abab",
            "cdcd",
            "abab",
            "cdcd",
        ])
        XCTAssertFalse(b.hasAnyMove, "this layout has no move")
        let idsBefore = Set(b.tiles.map { $0.tile.id })
        b.shuffle()
        XCTAssertEqual(Set(b.tiles.map { $0.tile.id }), idsBefore)
        XCTAssertTrue(b.findMatches().isEmpty)
        XCTAssertTrue(b.hasAnyMove)
    }

    func testAllShapesKeepColumnsContiguous() {
        for shape in BoardShape.allCases {
            for rows in 5...8 {
                for cols in 5...8 {
                    let mask = shape.mask(rows: rows, cols: cols)
                    XCTAssertTrue(BoardShape.columnsAreContiguous(mask), "\(shape) \(rows)x\(cols)")
                }
            }
        }
    }

    func testRefillRarelyCreatesFreeMatches() {
        // With 3 colors a random refill lands in a line most of the time; the match-avoiding
        // refill should almost never (only when every color would match).
        var b = Board(rows: 6, cols: 6, shape: .square, colorCount: 3, seed: 11)
        var spawns = 0, matchingSpawns = 0
        for i in 0..<300 {
            let p = Position(row: i % 6, col: (i * 7) % 6)
            b.remove([p])
            let result = b.applyGravityAndRefill()
            for s in result.spawns {
                spawns += 1
                if b.hasMatch(at: s.at) { matchingSpawns += 1 }
            }
            for g in b.findMatches() { b.remove(g.positions) }
            _ = b.applyGravityAndRefill()
        }
        XCTAssertGreaterThan(spawns, 200)
        XCTAssertLessThan(Double(matchingSpawns) / Double(spawns), 0.10, "\(matchingSpawns) of \(spawns) spawned tiles matched on arrival")
    }

    // MARK: - Playability guarantees

    /// Plays every level/assist/color-cap combination for a while with random valid moves,
    /// resolving cascades and shuffling when stuck, and checks the board can always
    /// progress: a valid move exists after every turn and shuffles never leave a match.
    func testEveryConfigurationStaysPlayable() {
        var rng = SeededRandom(seed: 99)
        var shuffles = 0
        for level in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20, 25, 30, 40, 50, 60, 80, 100, 150, 200] {
            for assist in 0...3 {
                for maxColors in [3, 4, 6] {
                    let config = LevelConfig(level: level, assist: assist, maxColors: maxColors)
                    var b = config.makeBoard()
                    let tag = "level \(level) assist \(assist) cap \(maxColors) (\(b.rows)x\(b.cols) \(config.shape) \(b.colorCount) colors)"
                    XCTAssertTrue(b.hasAnyMove, "\(tag): starts stuck")
                    XCTAssertTrue(b.findMatches().isEmpty, "\(tag): starts with a match")
                    for turn in 0..<40 {
                        guard let move = randomMove(in: b, rng: &rng) else {
                            XCTFail("\(tag): no move at turn \(turn)"); break
                        }
                        b.swap(move.0, move.1)
                        var cascades = 0
                        while true {
                            let groups = b.findMatches()
                            if groups.isEmpty { break }
                            for g in groups { b.remove(g.positions) }
                            _ = b.applyGravityAndRefill()
                            cascades += 1
                            XCTAssertLessThan(cascades, 50, "\(tag): endless cascade")
                        }
                        if !b.hasAnyMove {
                            b.shuffle()
                            shuffles += 1
                            XCTAssertTrue(b.hasAnyMove, "\(tag): still stuck after shuffle at turn \(turn)")
                            XCTAssertTrue(b.findMatches().isEmpty, "\(tag): shuffle left a match at turn \(turn)")
                        }
                    }
                }
            }
        }
        print("shuffles needed across the run: \(shuffles)")
    }

    /// The hardest case for random generation: the smallest boards with every color in
    /// play. Fresh boards and shuffles must always come out with a move.
    func testTinyBoardsWithSixColorsAlwaysHaveAMove() {
        let sizes: [(BoardShape, Int, Int)] = [
            (.square, 4, 4), (.square, 5, 4), (.square, 4, 5), (.roundedCorners, 5, 5),
            (.diamond, 6, 6), (.triangle, 6, 6), (.cross, 7, 7), (.octagon, 7, 7), (.circle, 7, 7), (.heart, 7, 7),
        ]
        for (shape, rows, cols) in sizes {
            for seed in 0..<300 {
                var b = Board(rows: rows, cols: cols, shape: shape, colorCount: 6, seed: UInt64(seed))
                XCTAssertTrue(b.hasAnyMove, "\(shape) \(rows)x\(cols) seed \(seed): fresh board stuck")
                XCTAssertTrue(b.findMatches().isEmpty, "\(shape) \(rows)x\(cols) seed \(seed): fresh board has a match")
                b.shuffle()
                XCTAssertTrue(b.hasAnyMove, "\(shape) \(rows)x\(cols) seed \(seed): stuck after shuffle")
                XCTAssertTrue(b.findMatches().isEmpty, "\(shape) \(rows)x\(cols) seed \(seed): match after shuffle")
            }
        }
    }

    /// The planted-move fallback must work on its own, in case random re-coloring ever
    /// exhausts its attempts: start from a board with no move and no match, and check the
    /// fallback produces a move without a match.
    func testPlantedMoveFallback() {
        var b = board([
            "abcd",
            "efab",
            "cdef",
            "abcd",
        ])
        XCTAssertFalse(b.hasAnyMove, "fixture should start stuck")
        b.forcePlantMove()
        XCTAssertTrue(b.hasAnyMove)
        XCTAssertTrue(b.findMatches().isEmpty)
    }

    /// A uniformly random valid move (not just the first one found), so play explores
    /// the board rather than always matching in the top-left corner.
    private func randomMove(in b: Board, rng: inout SeededRandom) -> (Position, Position)? {
        var moves: [(Position, Position)] = []
        for p in b.allPositions {
            for d in [Direction.right, .down] where b.swapCreatesMatch(p, p.offset(d)) { moves.append((p, p.offset(d))) }
        }
        guard !moves.isEmpty else { return nil }
        return moves[Int(rng.next() % UInt64(moves.count))]
    }

    // MARK: - Special candies

    func testMatchSizeDecidesTheEarnedPower() {
        let three = board(["aaab", "bcdb", "cdcb", "dcdd"]).findMatches()
        XCTAssertEqual(three.count, 2)
        XCTAssertTrue(three.allSatisfy { $0.earnedPower == nil })

        let four = board(["aaaa", "bcdb", "cdcb", "dcdd"]).findMatches()
        XCTAssertEqual(four.first?.earnedPower, .wrapped)

        let lShape = board(["aaab", "acdc", "adcb", "bcdd"]).findMatches()
        XCTAssertEqual(lShape.count, 1, "L shape should merge into one group")
        XCTAssertEqual(lShape.first?.earnedPower, .rainbow, "an L of five earns a rainbow")
        XCTAssertEqual(lShape.first?.earnedPower(allowed: [.wrapped, .striped]), .wrapped, "falls back before rainbows exist")

        let six = board(["aaaaaa", "bcdbcd", "cdcbdc", "dcddcd", "bcbdbc", "cdcbdb"]).findMatches()
        XCTAssertEqual(six.first?.earnedPower, .bomb, "six in a row earns a bomb")
        XCTAssertEqual(six.first?.earnedPower(allowed: [.wrapped, .striped, .rainbow]), .striped(.horizontal))
        XCTAssertEqual(six.first?.earnedPower(allowed: [.wrapped]), .wrapped)

        let bigT = board(["aaaaab", "bcadcd", "cdabdc", "dcdbcd", "bcbdbc", "cdcbdb"]).findMatches()
        XCTAssertEqual(bigT.count, 1)
        XCTAssertEqual(bigT.first?.positions.count, 7)
        XCTAssertEqual(bigT.first?.earnedPower, .bomb)
        XCTAssertEqual(bigT.first?.earnedPower(allowed: [.wrapped, .striped, .rainbow]), .rainbow)

        let five = board(["aaaaa", "bcdbc", "cdcbd", "dcddc", "bcbdb"]).findMatches()
        XCTAssertEqual(five.first?.earnedPower, .striped(.horizontal))

        let fiveDown = board(["abcde", "acdbc", "adcbd", "acddc", "abbdb"]).findMatches()
        XCTAssertEqual(fiveDown.first?.earnedPower, .striped(.vertical))
    }

    func testStripedClearsItsLineAndWrappedItsNeighbors() {
        var b = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        b.setPower(.striped(.horizontal), at: Position(row: 2, col: 2))
        let striped = b.expandedRemoval(for: [Position(row: 2, col: 2)])
        XCTAssertEqual(striped.removed, Set((0..<5).map { Position(row: 2, col: $0) } + (0..<5).map { Position(row: $0, col: 2) }), "row and column")
        XCTAssertEqual(striped.triggered.map(\.position), [Position(row: 2, col: 2)])

        b.setPower(.wrapped, at: Position(row: 0, col: 0))
        let wrapped = b.expandedRemoval(for: [Position(row: 0, col: 0)])
        XCTAssertEqual(wrapped.removed, Set([Position(row: 0, col: 0), Position(row: 0, col: 1), Position(row: 1, col: 0), Position(row: 1, col: 1)]))

        // Plain candies trigger nothing.
        let plain = b.expandedRemoval(for: [Position(row: 4, col: 4)])
        XCTAssertEqual(plain.removed, [Position(row: 4, col: 4)])
        XCTAssertTrue(plain.triggered.isEmpty)
    }

    func testPowersChainAndTerminate() {
        var b = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        for p in b.allPositions { b.setPower(.striped((p.row + p.col) % 2 == 0 ? .horizontal : .vertical), at: p) }
        let all = b.expandedRemoval(for: [Position(row: 0, col: 0)])
        XCTAssertEqual(all.removed.count, 25, "a board of striped candies clears entirely")
        XCTAssertEqual(all.triggered.count, 25)
    }

    func testBombClearsFiveByFive() {
        var b = board(["abcdeab", "bcdeabc", "cdeabcd", "deabcde", "eabcdea", "abcdeab", "bcdeabc"])
        b.setPower(.bomb, at: Position(row: 3, col: 3))
        let r = b.expandedRemoval(for: [Position(row: 3, col: 3)])
        XCTAssertEqual(r.removed.count, 25)
        XCTAssertTrue(r.removed.contains(Position(row: 1, col: 1)))
        XCTAssertFalse(r.removed.contains(Position(row: 0, col: 0)))
        // At a corner it is clipped by the board.
        b.setPower(.bomb, at: Position(row: 0, col: 0))
        XCTAssertEqual(b.expandedRemoval(for: [Position(row: 0, col: 0)]).removed.count, 9)
    }

    func testRainbowHasNoColorAndGoesOffOnASwipe() {
        var b = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        let r = Position(row: 2, col: 2)
        b.setPower(.rainbow, at: r)
        // It never completes a line, whatever its stored color.
        var line = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        line.overwrite(with: ["abcde", "bcdeb", "eeebc", "debcd", "ebcde"])
        line.setPower(.rainbow, at: Position(row: 2, col: 1))
        XCTAssertTrue(line.findMatches().isEmpty, "a rainbow breaks the run it sits in")
        XCTAssertNil(line.matchColor(at: Position(row: 2, col: 1)))

        // Swiping it onto a neighbor is always a move, and clears that neighbor's color.
        let right = Position(row: 2, col: 3)
        XCTAssertEqual(b.swapEffect(r, right, combos: false), .rainbow(color: b.tile(at: right)!.color, at: right))
        XCTAssertEqual(b.swapEffect(right, r, combos: false), .rainbow(color: b.tile(at: right)!.color, at: right))
        XCTAssertNotNil(b.findAnyMove())
        let color = b.tile(at: right)!.color
        b.swap(r, right)
        let cleared = b.rainbowRemoval(color: color, at: right)
        XCTAssertEqual(cleared.removed, Set(b.positions(of: color) + [right]))
        XCTAssertEqual(cleared.removed.count, b.positions(of: color).count + 1, "every candy of the color plus the rainbow itself")
        XCTAssertEqual(cleared.removed.count, 7)
        XCTAssertEqual(cleared.triggered.map(\.power), [.rainbow])
    }

    func testRainbowCaughtInABlastTakesTheMostCommonColor() {
        var b = board(["aaaab", "bcdeb", "cdebc", "debcd", "ebcde"])
        b.overwrite(with: ["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        b.overwrite(with: ["abade", "acaab", "cdebc", "deacd", "ebcde"])  // a x6 is the most common
        b.setPower(.rainbow, at: Position(row: 4, col: 4))
        b.setPower(.wrapped, at: Position(row: 3, col: 3))
        XCTAssertEqual(b.mostCommonColor, TileColor(0))
        let r = b.expandedRemoval(for: [Position(row: 3, col: 3)])
        XCTAssertTrue(b.positions(of: TileColor(0)).allSatisfy { r.removed.contains($0) })
        XCTAssertEqual(Set(r.triggered.map(\.power)), [.wrapped, .rainbow])
    }

    func testCombosAreMovesOnlyWhenUnlocked() {
        var b = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        let a = Position(row: 2, col: 2), c = Position(row: 2, col: 3)
        b.setPower(.striped(.horizontal), at: a)
        b.setPower(.wrapped, at: c)
        XCTAssertEqual(b.swapEffect(a, c, combos: false), .none, "two specials are a plain (invalid) swap before combos")
        XCTAssertEqual(b.swapEffect(a, c, combos: true), .combo(a, c))

        b.swap(a, c)
        let r = b.comboRemoval(a, c)
        // Three rows and three columns around the pair's landing cell.
        for row in 1...3 { for col in 0..<5 { XCTAssertTrue(r.removed.contains(Position(row: row, col: col))) } }
        for col in 2...4 { for row in 0..<5 { XCTAssertTrue(r.removed.contains(Position(row: row, col: col))) } }
        XCTAssertFalse(r.removed.contains(Position(row: 0, col: 0)))
        XCTAssertFalse(r.removed.contains(Position(row: 4, col: 1)))

        var two = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        two.setPower(.striped(.vertical), at: a)
        two.setPower(.striped(.horizontal), at: c)
        XCTAssertEqual(two.comboRemoval(a, c).removed.count, 25, "two striped clear the board")

        var rainbow = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        rainbow.setPower(.rainbow, at: a)
        rainbow.setPower(.wrapped, at: c)
        let cColor = rainbow.tile(at: c)!.color
        let r2 = rainbow.comboRemoval(a, c)
        XCTAssertTrue(rainbow.positions(of: cColor).allSatisfy { r2.removed.contains($0) })
        XCTAssertGreaterThan(r2.removed.count, rainbow.positions(of: cColor).count + 1, "every candy of that color burst as a wrapped one")
        XCTAssertTrue(r2.triggered.filter { $0.power == .wrapped }.count >= rainbow.positions(of: cColor).count)
    }

    func testShuffleAndGravityKeepPowers() {
        var b = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        b.setPower(.wrapped, at: Position(row: 0, col: 1))
        let id = b.tile(at: Position(row: 0, col: 1))!.id
        b.remove([Position(row: 4, col: 1)])
        _ = b.applyGravityAndRefill()
        let afterFall = b.tiles.first { $0.tile.id == id }
        XCTAssertEqual(afterFall?.tile.power, .wrapped)
        XCTAssertEqual(afterFall?.position, Position(row: 1, col: 1))
        b.shuffle()
        XCTAssertEqual(b.tiles.first { $0.tile.id == id }?.tile.power, .wrapped)
    }
}

extension BoardTests {
    func testWildcardJoinsAnyLine() {
        var b = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        let w = Position(row: 2, col: 2)
        XCTAssertFalse(b.wildSpawnCandidates().isEmpty)
        b.overwrite(with: ["abcde", "bcdeb", "cdabc", "debcd", "ebcde"])  // row 2: c d a b c
        b.setPower(.wild, at: w)
        XCTAssertTrue(b.findMatches().isEmpty, "d W b is not a line")
        b.overwrite(with: ["abcde", "bcdeb", "cddbc", "debcd", "ebcde"])  // row 2: c d W b c (d at col 1)
        b.setPower(.wild, at: w)
        b.setCell(row: 2, col: 3, Tile(color: TileColor(3)))                // c d W d c
        let groups = b.findMatches()
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.positions, Set([Position(row: 2, col: 1), w, Position(row: 2, col: 3)]))
        XCTAssertEqual(groups.first?.color, TileColor(3))
        XCTAssertTrue(b.hasMatch(at: w))
        XCTAssertTrue(b.hasWild)
        // Cleared with the match, no blast, not a trigger.
        let r = b.expandedRemoval(for: groups[0].positions)
        XCTAssertEqual(r.removed, groups[0].positions)
        XCTAssertTrue(r.triggered.isEmpty)
        // A swipe that lines two of a color up with the star is a move.
        var c = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        c.setPower(.wild, at: Position(row: 0, col: 0))                      // row 0: W b c d e
        c.setCell(row: 0, col: 2, Tile(color: TileColor(4)))                 // row 0: W b e d e
        c.setCell(row: 1, col: 1, Tile(color: TileColor(4)))                 // an e under the b
        XCTAssertTrue(c.findMatches().isEmpty)
        XCTAssertEqual(c.swapEffect(Position(row: 0, col: 1), Position(row: 1, col: 1), combos: false), .match,
                       "swapping the e up makes W e e")
        c.swap(Position(row: 0, col: 1), Position(row: 1, col: 1))
        XCTAssertEqual(c.findMatches().first?.positions, Set([Position(row: 0, col: 0), Position(row: 0, col: 1), Position(row: 0, col: 2)]))
        // Refill never completes a line through the star.
        var d = board(["abcde", "bcdeb", "cdebc", "debcd", "ebcde"])
        d.setPower(.wild, at: Position(row: 4, col: 2))
        for _ in 0..<30 {
            d.remove([Position(row: 0, col: 2)])
            _ = d.applyGravityAndRefill()
            XCTAssertTrue(d.findMatches().isEmpty, "refill made a line through the wildcard")
        }
    }
}
