import XCTest
@testable import Match3Core

final class LevelConfigTests: XCTestCase {

    func testFirstLevelsAreGentle() {
        let l1 = LevelConfig(level: 1)
        XCTAssertEqual(l1.rows, 4)
        XCTAssertEqual(l1.cols, 4)
        XCTAssertEqual(l1.colorCount, 3)
        XCTAssertEqual(l1.goalMatches, 3)
        XCTAssertEqual(l1.shape, .square)
        XCTAssertNotEqual(LevelConfig(level: 2).rows, LevelConfig(level: 2).cols, "level 2 is not square")
        XCTAssertEqual(LevelConfig(level: 12).colorCount, 3, "three colors well past level 5")
        XCTAssertEqual(LevelConfig(level: 13).colorCount, 4)
    }

    func testBoundsAndGrowthAreMonotonicWhereExpected() {
        var previousColors = 0
        var previousGoal = 0
        for level in 1...200 {
            let c = LevelConfig(level: level)
            XCTAssertTrue(c.colorCount >= 3 && c.colorCount <= LevelConfig.maxColors)
            XCTAssertTrue(c.rows <= LevelConfig.maxRows && c.cols <= LevelConfig.maxCols)
            XCTAssertTrue(c.goalMatches >= 3 && c.goalMatches <= LevelConfig.maxGoal)
            XCTAssertGreaterThanOrEqual(c.colorCount, previousColors)
            XCTAssertGreaterThanOrEqual(c.goalMatches, previousGoal)
            previousColors = c.colorCount
            previousGoal = c.goalMatches
            let playable = c.shape.mask(rows: c.rows, cols: c.cols).flatMap { $0 }.filter { $0 }.count
            XCTAssertGreaterThanOrEqual(playable, LevelConfig.minPlayableCells, "level \(level) too few cells")
        }
    }

    func testIsDeterministic() {
        let a = LevelConfig(level: 17).makeBoard()
        let b = LevelConfig(level: 17).makeBoard()
        XCTAssertEqual(a.tiles.map { $0.tile.color }, b.tiles.map { $0.tile.color })
    }

    func testShapesVaryAfterLevelEight() {
        let shapes = Set((1...12).map { LevelConfig(level: $0).shape })
        XCTAssertGreaterThanOrEqual(shapes.count, 5)
    }

    func testAssistSoftensWithoutBreakingBoards() {
        for level in 1...60 {
            let base = LevelConfig(level: level)
            for assist in 1...AssistPolicy.maxAssist {
                let c = LevelConfig(level: level, assist: assist)
                XCTAssertLessThanOrEqual(c.colorCount, base.colorCount)
                XCTAssertLessThanOrEqual(c.goalMatches, base.goalMatches)
                XCTAssertLessThanOrEqual(c.rows * c.cols, base.rows * base.cols)
                XCTAssertGreaterThanOrEqual(c.colorCount, 3)
                XCTAssertGreaterThanOrEqual(c.goalMatches, 3)
                let board = c.makeBoard()
                XCTAssertTrue(board.hasAnyMove, "level \(level) assist \(assist) stuck")
                XCTAssertTrue(board.findMatches().isEmpty)
            }
        }
        XCTAssertEqual(LevelConfig(level: 50, assist: 3).colorCount, LevelConfig(level: 50).colorCount - 3)
        XCTAssertEqual(LevelConfig(level: 1, assist: 3).rows, 4, "never below 4x4")
        XCTAssertEqual(LevelConfig(level: 50, maxColors: 4).colorCount, 4, "caregiver cap")
        XCTAssertEqual(LevelConfig(level: 50, maxColors: 1).colorCount, 3, "cap clamps to 3")
    }
}

final class AssistPolicyTests: XCTestCase {
    func testStruggleRaisesAndBreezeLowers() {
        let struggled = LevelStats(matches: 5, invalidSwaps: 9, hintsShown: 1, seconds: 60)
        XCTAssertEqual(AssistPolicy.next(after: struggled, current: 0), 1)
        XCTAssertEqual(AssistPolicy.next(after: struggled, current: 3), 3, "capped")

        let breezed = LevelStats(matches: 5, invalidSwaps: 1, hintsShown: 0, seconds: 20)
        XCTAssertEqual(AssistPolicy.next(after: breezed, current: 2), 1)
        XCTAssertEqual(AssistPolicy.next(after: breezed, current: 0), 0, "never negative")

        let normal = LevelStats(matches: 5, invalidSwaps: 4, hintsShown: 1, seconds: 60)
        XCTAssertEqual(AssistPolicy.next(after: normal, current: 1), 1)

        let manyHints = LevelStats(matches: 5, invalidSwaps: 0, hintsShown: 3, seconds: 40)
        XCTAssertEqual(AssistPolicy.next(after: manyHints, current: 0), 1)
    }
}
