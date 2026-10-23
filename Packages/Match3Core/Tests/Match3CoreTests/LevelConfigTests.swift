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
}
