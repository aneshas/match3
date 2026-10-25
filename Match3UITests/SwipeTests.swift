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
        let app = launch(level: 5)  // 4 rows x 5 cols (`LevelConfig.openingSizes`)
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

    /// After "start again" in the caregiver panel the Play button must unlock immediately.
    func testResetInPanelUnlocksPlayWithoutRelaunch() {
        let app = XCUIApplication()
        app.launchEnvironment = ["MATCH3_MUTE": "1", "MATCH3_FREE_LEVELS": "1", "MATCH3_PANEL": "1"]
        app.launchArguments = ["-lifetimeCompleted", "0"]  // the lifetime cap must not be what locks Play here
        app.launch()
        // Make sure we are past the free levels: finish nothing, just pretend via the caregiver reset path later.
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "panel did not open")
        done.tap()
        sleep(1)
        // Precondition for this test: the simulator must already be past level 1 (see runner script).
        let locked = app.buttons["Locked"]
        XCTAssertTrue(locked.waitForExistence(timeout: 3), "expected the locked Play button")

        // Reopen the panel (Debug: hold the logo) and start again.
        app.images["logo"].press(forDuration: 3.5)
        XCTAssertTrue(done.waitForExistence(timeout: 5), "panel did not reopen")
        let reset = app.buttons["Start again from level 1"]
        for _ in 0..<4 where !reset.exists { app.swipeUp() }
        reset.tap()
        app.buttons["Start again"].tap()
        sleep(1)
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3), "Play button still locked after reset")
    }
}
