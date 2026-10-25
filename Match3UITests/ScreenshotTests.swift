import StoreKitTest
import XCTest

/// Store screenshot helper, not a test of behaviour: opens the caregiver panel with the
/// local store attached (so the unlock row shows its price, which headless `simctl`
/// launches cannot) and holds it on screen so `simctl io screenshot` can capture it.
/// Runs only with `TEST_RUNNER_MATCH3_HOLD_PANEL=1` on the xcodebuild command line.
final class ScreenshotTests: XCTestCase {

    func testHoldsCaregiverPanelAtTheUnlockRow() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["MATCH3_HOLD_PANEL"] != nil)
        let session = try SKTestSession(configurationFileNamed: "Match3")
        session.disableDialogs = true
        session.clearTransactions()

        let app = XCUIApplication()
        app.launchEnvironment = ["MATCH3_MUTE": "1", "MATCH3_PANEL": "1"]
        app.launch()

        let buy = app.buttons["unlock.buy"]
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 8), "panel did not open")
        for _ in 0..<8 where !buy.isHittable { app.swipeUp() }
        XCTAssertTrue(buy.waitForExistence(timeout: 8), "buy button missing")
        XCTAssertTrue(buy.label.contains("9.99"), "price not shown: \(buy.label)")
        XCTAssertTrue(buy.isHittable, "buy row not on screen")
        // Two poses, 15 s each: the Buy row where the swipe left it, then nudged up a little
        // so the rows below it (Restore, institutions) show too.
        sleep(15)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -180)))
        sleep(15)
    }
}
