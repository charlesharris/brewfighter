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
    func testCellarPseudoLocalized() {
        let app = launchApp(reset: true, pseudoLocalized: true)
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))

        assertDoubled(app.staticTexts["cellar.title"].label)
        assertDoubled(brew.label)
        attachScreenshot(app, name: "pseudo-cellar")
    }
}
