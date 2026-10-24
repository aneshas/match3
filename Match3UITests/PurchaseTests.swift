import StoreKitTest
import XCTest

/// Buys the unlock through StoreKit's local test store (no sheet) and checks the caregiver
/// panel reports it. Needs the simulator's `allLevelsUnlocked` default cleared first.
final class PurchaseTests: XCTestCase {

    func testBuyingTheUnlockFlipsThePanel() throws {
        let session = try SKTestSession(configurationFileNamed: "Match3")
        session.disableDialogs = true
        session.clearTransactions()

        let app = XCUIApplication()
        app.launchEnvironment = ["MATCH3_MUTE": "1", "MATCH3_PANEL": "1"]
        app.launch()

        let buy = app.buttons["unlock.buy"]
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 8), "panel did not open")
        for _ in 0..<6 where !buy.exists { app.swipeUp() }
        XCTAssertTrue(buy.waitForExistence(timeout: 8), "buy button missing (product not loaded?)")
        XCTAssertTrue(buy.label.contains("9.99"), "price not shown: \(buy.label)")
        buy.tap()

        // Parental gate: read "a × b" from the alert and answer it.
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "parental gate did not appear")
        let text = alert.staticTexts.allElementsBoundByIndex.map(\.label).first { $0.contains("×") } ?? ""
        let numbers = text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        XCTAssertEqual(numbers.count, 2, "could not parse the gate question: \(text)")
        let field = alert.textFields.firstMatch
        field.tap()
        field.typeText("\(numbers[0] * numbers[1])")
        alert.buttons["Continue"].tap()

        let unlocked = app.staticTexts["All levels are unlocked"]
        XCTAssertTrue(unlocked.waitForExistence(timeout: 8), "panel did not report the unlock")

        // The unlock must survive a relaunch (entitlement + cache).
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 8), "panel did not reopen")
        for _ in 0..<6 where !unlocked.exists { app.swipeUp() }
        XCTAssertTrue(unlocked.waitForExistence(timeout: 8), "unlock lost after relaunch")
        session.clearTransactions()
    }
}
