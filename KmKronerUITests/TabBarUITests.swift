//
//  TabBarUITests.swift
//  KmKronerUITests
//

import XCTest

// UI tests still use XCTest: Swift Testing has no UI automation support.
// The app runs as a separate process, driven through XCUIApplication.
@MainActor
final class TabBarUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testFourTabsAndSettingsShowsVersion() {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        for title in ["Today", "Calendar", "Summary", "Settings"] {
            XCTAssertTrue(tabBar.buttons[title].waitForExistence(timeout: 5), "Missing tab: \(title)")
        }

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Version"].waitForExistence(timeout: 5))
    }
}
