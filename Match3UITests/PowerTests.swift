import XCTest

/// Special candies end to end: with MATCH3_POWER_DEMO the first move autoplay makes contains
/// a wrapped and a striped candy, so at least one must go off and the bar must jump by
/// more than the plain match would give.
final class PowerTests: XCTestCase {

    func testSpecialCandiesGoOffOnTheDemoMove() {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "MATCH3_AUTOSTART": "1", "MATCH3_AUTOPLAY": "1", "MATCH3_LEVEL": "4",
            "MATCH3_POWER_DEMO": "1", "MATCH3_MUTE": "1",
        ]
        app.launch()
        let counters = app.staticTexts["debug.counters"]
        XCTAssertTrue(counters.waitForExistence(timeout: 8))
        // Entrance (about 1.5 s) + autoplay delay + the first match and its cascade.
        var powers = -1
        for _ in 0..<20 {
            sleep(1)
            let parts = counters.label.split(separator: " ")
            if let i = parts.firstIndex(of: "powers"), let n = Int(parts[i + 1]) { powers = n }
            if powers > 0 { break }
        }
        XCTAssertGreaterThan(powers, 0, "no special candy went off on the demo move; counters: \(counters.label)")
    }

    /// The rainbow candy (planted by MATCH3_POWER_DEMO, found through its accessibility value)
    /// goes off when swiped toward any neighbor, with no match needed.
    func testRainbowGoesOffOnASwipe() {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "MATCH3_AUTOSTART": "1", "MATCH3_LEVEL": "4", "MATCH3_POWER_DEMO": "1", "MATCH3_MUTE": "1",
        ]
        app.launch()
        let counters = app.staticTexts["debug.counters"]
        XCTAssertTrue(counters.waitForExistence(timeout: 8))
        sleep(3)  // entrance animation
        let rainbow = app.images.matching(NSPredicate(format: "identifier BEGINSWITH 'tile.' AND value == 'rainbow'")).firstMatch
        XCTAssertTrue(rainbow.waitForExistence(timeout: 3), "no rainbow candy on the demo board")
        let parts = rainbow.identifier.split(separator: ".")
        let row = Int(parts[1])!, col = Int(parts[2])!
        let neighborCol = col > 0 ? col - 1 : col + 1
        let neighbor = app.images["tile.\(row).\(neighborCol)"]
        XCTAssertTrue(neighbor.waitForExistence(timeout: 2))
        rainbow.press(forDuration: 0.05, thenDragTo: neighbor)
        var powers = 0
        for _ in 0..<10 {
            sleep(1)
            let p = counters.label.split(separator: " ")
            if let i = p.firstIndex(of: "powers"), let n = Int(p[i + 1]) { powers = n }
            if powers > 0 { break }
        }
        XCTAssertGreaterThan(powers, 0, "the rainbow did not go off; counters: \(counters.label)")
    }
}
