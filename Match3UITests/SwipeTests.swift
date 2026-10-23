import XCTest

/// Drives real touches on the simulator. Used to verify that swipes work on every column,
/// including under one-sided safe-area insets (iPhone Duo cover screen).
final class SwipeTests: XCTestCase {

    private func launch(level: Int) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "MATCH3_AUTOSTART": "1", "MATCH3_LEVEL": "\(level)", "MATCH3_MUTE": "1",
        ]
        app.launch()
        sleep(3)  // entrance animation
        return app
    }

    private func swipes(in app: XCUIApplication) -> Int {
        let label = app.staticTexts["debug.counters"].label
        let parts = label.split(separator: " ")
        return Int(parts[1]) ?? -1
    }

    func testEveryColumnAcceptsASwipe() {
        let app = launch(level: 3)  // 4 rows x 5 cols
        var failures: [String] = []
        for col in 0..<5 {
            let from = app.images["tile.1.\(col)"]
            let to = app.images["tile.2.\(col)"]
            XCTAssertTrue(from.waitForExistence(timeout: 2), "tile.1.\(col) missing")
            let before = swipes(in: app)
            from.press(forDuration: 0.05, thenDragTo: to)
            sleep(2)  // let any swap/cascade settle
            let after = swipes(in: app)
            if after <= before { failures.append("column \(col) (frame \(from.frame))") }
        }
        XCTAssertTrue(failures.isEmpty, "swipe not received on: \(failures.joined(separator: ", "))")
    }
}
