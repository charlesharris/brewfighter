import XCTest

final class ChromeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testCellarEmptyChrome() throws {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["cellar.empty"].exists)

        assertTouchTargets(in: app)
        assertNoRawCatalogKeys(in: app)
        assertInThumbZone(brew, app: app)
        XCTAssertGreaterThanOrEqual(brew.frame.height, 44)
        try app.performAccessibilityAudit(for: .hitRegion)
    }

    @MainActor
    func testCellarWithBeerChrome() throws {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))
        brew.tap()
        XCTAssertTrue(app.descendants(matching: .any)["cellar.beer.1"].waitForExistence(timeout: 5))

        assertTouchTargets(in: app)
        assertNoRawCatalogKeys(in: app)
        assertInThumbZone(brew, app: app)
        try app.performAccessibilityAudit(for: .hitRegion)
    }

    @MainActor
    func testSaveTransferSheetChrome() throws {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))
        brew.tap()
        XCTAssertTrue(app.descendants(matching: .any)["cellar.beer.1"].waitForExistence(timeout: 5))

        app.buttons["cellar.saveTransfer"].tap()
        let export = app.buttons["saveTransfer.export"]
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(export.frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["saveTransfer.import"].frame.height, 44)

        assertTouchTargets(in: app)
        assertNoRawCatalogKeys(in: app)
        attachScreenshot(app, name: "save-transfer-sheet")
    }

    @MainActor
    func testCellarPseudoLocalized() {
        let app = launchApp(reset: true, pseudoLocalized: true)
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))

        assertDoubled(app.staticTexts["cellar.title"].label)
        assertDoubled(brew.label)
        attachScreenshot(app, name: "pseudo-cellar")

        let open = app.buttons["cellar.saveTransfer"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        assertDoubled(open.label)
        open.tap()
        let export = app.buttons["saveTransfer.export"]
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        assertDoubled(app.staticTexts["saveTransfer.title"].label)
        assertDoubled(export.label)
        assertDoubled(app.buttons["saveTransfer.import"].label)
        attachScreenshot(app, name: "pseudo-save-transfer")
    }
}
