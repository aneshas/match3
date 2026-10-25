import XCTest
@testable import Match3Core

/// The special-candy lessons: on every board a level can produce, each lesson can be
/// planted, nothing matches before the swipe, the swipe earns exactly the taught special,
/// and once it sits on the board a second swipe sets it off.
final class TutorialTests: XCTestCase {

    private func power(_ kind: PowerKind) -> Power {
        switch kind {
        case .wrapped: return .wrapped
        case .striped: return .striped(.horizontal)
        case .rainbow: return .rainbow
        case .bomb: return .bomb
        }
    }

    func testEveryLessonPlantsOnEveryBoardShape() {
        var planted = 0
        for level in 10...60 {
            for variant in 0..<2 {
                for kind in PowerKind.allCases {
                    let config = LevelConfig(level: level, variant: variant)
                    var b = config.makeBoard()
                    guard let move = b.plantPowerSpawn(kind) else {
                        XCTFail("no \(kind) lesson fits level \(level) (\(config.rows)x\(config.cols) \(config.shape))"); continue
                    }
                    XCTAssertTrue(b.findMatches().isEmpty, "lesson board matches before the swipe (level \(level), \(kind))")
                    XCTAssertEqual(b.swapEffect(move.from, move.to, combos: false), .match)
                    b.swap(move.from, move.to)
                    let groups = b.findMatches()
                    XCTAssertEqual(groups.count, 1, "the lesson swipe makes exactly one match (level \(level), \(kind))")
                    XCTAssertEqual(groups.first?.earnedPower(allowed: [kind])?.kind, kind)
                    XCTAssertTrue(groups.first?.positions.contains(move.to) ?? false, "the moved candy is in the match")

                    // The special appears where the moved candy landed; the rest of the group clears.
                    var removed = groups[0].positions
                    removed.remove(move.to)
                    b.remove(removed)
                    b.setPower(power(kind), at: move.to)
                    _ = b.applyGravityAndRefill()
                    guard let s = b.position(ofPower: kind) else { XCTFail("special lost"); continue }
                    guard let trigger = b.plantPowerTrigger(at: s) else {
                        XCTFail("no trigger lesson fits level \(level) \(kind) at \(s)"); continue
                    }
                    if kind == .rainbow {
                        XCTAssertEqual(trigger.from, s)
                        if case .rainbow = b.swapEffect(trigger.from, trigger.to, combos: false) {} else { XCTFail("rainbow swipe") }
                    } else {
                        XCTAssertEqual(trigger.from, s, "the player drags the special itself")
                        XCTAssertEqual(b.swapEffect(trigger.from, trigger.to, combos: false), .match)
                        b.swap(trigger.from, trigger.to)
                        let base = Set(b.findMatches().flatMap { $0.positions })
                        XCTAssertTrue(b.expandedRemoval(for: base).triggered.contains { $0.power.kind == kind },
                                      "the trigger swipe sets the \(kind) off (level \(level))")
                    }
                    planted += 1
                }
            }
        }
        XCTAssertEqual(planted, 51 * 2 * 4)
    }

    func testComboLessonPlantsTwoSpecialsSideBySide() {
        let config = LevelConfig(level: LevelConfig.combosFromLevel)
        var b = config.makeBoard()
        guard let move = b.plantCombo() else { return XCTFail("no combo lesson") }
        XCTAssertTrue(move.from.isAdjacent(to: move.to))
        XCTAssertEqual(b.swapEffect(move.from, move.to, combos: true), .combo(move.from, move.to))
        XCTAssertTrue(b.findMatches().isEmpty)
    }
}
