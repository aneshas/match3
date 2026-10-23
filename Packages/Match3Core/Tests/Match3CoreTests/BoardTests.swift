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
}
