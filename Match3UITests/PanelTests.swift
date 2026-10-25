import XCTest

/// The hidden caregiver entry. XCUITest cannot hold two fingers, so this drives the Debug
/// one-finger hold, which lives on the same UIKit view and recognizer setup as the
/// two-finger one (`TwoFingerHold`).
final class PanelTests: XCTestCase {

    func testHoldingTheLogoOpensTheCaregiverPanel() {
        let app = XCUIApplication()
        app.launchEnvironment = ["MATCH3_MUTE": "1"]
        app.launch()
        let logo = app.images["logo"]
        XCTAssertTrue(logo.waitForExistence(timeout: 8), "logo missing")
        XCTAssertFalse(app.buttons["Done"].exists, "panel open before the hold")
        logo.press(forDuration: 3.6)
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5), "panel did not open after the hold")
    }

    func testAShortTouchOnTheLogoDoesNothing() {
        let app = XCUIApplication()
        app.launchEnvironment = ["MATCH3_MUTE": "1"]
        app.launch()
        let logo = app.images["logo"]
        XCTAssertTrue(logo.waitForExistence(timeout: 8), "logo missing")
        logo.press(forDuration: 1.0)
        sleep(1)
        XCTAssertFalse(app.buttons["Done"].exists, "panel opened on a short touch")
    }
}
