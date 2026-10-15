import XCTest

final class ChromeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testCellarEmptyChrome() throws {
        let app = launchApp(reset: true, pseudoLocalized: false)
        closeWizardToCellar(in: app)
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
        brewFromWizard(in: app, expecting: "cellar.beer.1")
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))

        assertTouchTargets(in: app)
        assertNoRawCatalogKeys(in: app)
        assertInThumbZone(brew, app: app)
        try app.performAccessibilityAudit(for: .hitRegion)
    }

    @MainActor
    func testSaveTransferSheetChrome() throws {
        let app = launchApp(reset: true, pseudoLocalized: false)
        brewFromWizard(in: app, expecting: "cellar.beer.1")
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))

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
        closeWizardToCellar(in: app)
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

    @MainActor
    func testMashStageChrome() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let next = app.buttons["wizard.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        assertInThumbZone(next, app: app)

        // Open the card controls so the stepper, base and remove buttons are on screen too.
        app.buttons["mash.card.grain.g04"].tap()
        for _ in 0..<4 {
            assertTouchTargets(in: app)
            assertNoRawCatalogKeys(in: app)
            dragWizardBody(in: app, up: true)
        }
    }

    @MainActor
    func testMashStagePseudoLocalized() {
        let app = launchApp(reset: true, pseudoLocalized: true)
        let next = app.buttons["wizard.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        assertDoubled(next.label)
        assertDoubled(app.buttons["wizard.close"].label)
        attachScreenshot(app, name: "pseudo-mash")
    }

    @MainActor
    func testBoilStageChrome() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let next = app.buttons["wizard.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        next.tap()
        XCTAssertTrue(app.buttons["boil.slot.aroma"].waitForExistence(timeout: 5))
        assertInThumbZone(next, app: app)

        for _ in 0..<4 {
            assertTouchTargets(in: app)
            assertNoRawCatalogKeys(in: app)
            dragWizardBody(in: app, up: true)
        }
    }

    @MainActor
    func testBoilStagePseudoLocalized() {
        let app = launchApp(reset: true, pseudoLocalized: true)
        let next = app.buttons["wizard.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        next.tap()
        XCTAssertTrue(app.buttons["boil.slot.aroma"].waitForExistence(timeout: 5))
        attachScreenshot(app, name: "pseudo-boil")
    }

    @MainActor
    func testFermentAndConditionChrome() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let ferment = app.buttons["wizard.stage.ferment"]
        XCTAssertTrue(ferment.waitForExistence(timeout: 10))
        ferment.tap()
        XCTAssertTrue(app.buttons["ferment.temp.cold"].waitForExistence(timeout: 5))
        assertInThumbZone(app.buttons["wizard.next"], app: app)
        for _ in 0..<4 {
            assertTouchTargets(in: app)
            assertNoRawCatalogKeys(in: app)
            dragWizardBody(in: app, up: true)
        }

        app.buttons["wizard.stage.condition"].tap()
        XCTAssertTrue(app.buttons["condition.card.fruit"].waitForExistence(timeout: 5))
        assertInThumbZone(app.buttons["wizard.next"], app: app)
        // The seeded dry hop is already expanded; turn fruit on too so both sets of controls show.
        tapScrolling(app.buttons["condition.card.fruit"], in: app)
        XCTAssertTrue(app.buttons["condition.fruit.amount.increase"].waitForExistence(timeout: 5))
        for _ in 0..<6 {
            assertTouchTargets(in: app)
            assertNoRawCatalogKeys(in: app)
            dragWizardBody(in: app, up: true)
        }
    }

    @MainActor
    func testFermentAndConditionPseudoLocalized() {
        let app = launchApp(reset: true, pseudoLocalized: true)
        let ferment = app.buttons["wizard.stage.ferment"]
        XCTAssertTrue(ferment.waitForExistence(timeout: 10))
        ferment.tap()
        XCTAssertTrue(app.buttons["ferment.temp.cold"].waitForExistence(timeout: 5))
        assertDoubled(app.buttons["wizard.next"].label)
        attachScreenshot(app, name: "pseudo-ferment")

        app.buttons["wizard.stage.condition"].tap()
        XCTAssertTrue(app.buttons["condition.card.lagering"].waitForExistence(timeout: 5))
        assertDoubled(app.buttons["wizard.back"].label)
        attachScreenshot(app, name: "pseudo-condition")
    }
}
