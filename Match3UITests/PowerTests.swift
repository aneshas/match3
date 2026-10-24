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
}
