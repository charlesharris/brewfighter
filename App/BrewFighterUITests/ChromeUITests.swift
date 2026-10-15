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

    @MainActor
    func testReviewChrome() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        XCTAssertTrue(app.buttons["wizard.clear"].waitForExistence(timeout: 10))
        app.buttons["wizard.clear"].tap()
        app.buttons["wizard.stage.review"].tap()

        // With issues: the issues panel, Fix buttons and a disabled BREW.
        XCTAssertTrue(app.buttons["review.fix.noGrain"].waitForExistence(timeout: 5))
        let brew = app.buttons["review.brew"]
        assertInThumbZone(brew, app: app)
        for _ in 0..<3 {
            assertTouchTargets(in: app)
            assertNoRawCatalogKeys(in: app)
            dragWizardBody(in: app, up: true)
        }

        // Without issues: fix both and look again.
        dragWizardBody(in: app, up: false)
        dragWizardBody(in: app, up: false)
        dragWizardBody(in: app, up: false)
        app.buttons["review.fix.noGrain"].tap()
        app.buttons["mash.card.grain.g02"].tap()
        app.buttons["wizard.stage.review"].tap()
        app.buttons["review.fix.noYeast"].tap()
        tapScrolling(app.buttons["ferment.card.yeast.y03"], in: app)
        app.buttons["wizard.stage.review"].tap()
        XCTAssertTrue(element("review.dayCost", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["review.fix.noYeast"].exists)
        assertInThumbZone(brew, app: app)
        for _ in 0..<3 {
            assertTouchTargets(in: app)
            assertNoRawCatalogKeys(in: app)
            dragWizardBody(in: app, up: true)
        }
    }

    @MainActor
    func testReviewPseudoLocalized() {
        let app = launchApp(reset: true, pseudoLocalized: true)
        XCTAssertTrue(app.buttons["wizard.clear"].waitForExistence(timeout: 10))
        app.buttons["wizard.clear"].tap()
        app.buttons["wizard.stage.review"].tap()
        XCTAssertTrue(app.buttons["review.fix.noGrain"].waitForExistence(timeout: 5))
        assertDoubled(app.buttons["review.fix.noGrain"].label)
        assertDoubled(app.buttons["review.brew"].label)
        attachScreenshot(app, name: "pseudo-review")
    }

    @MainActor
    func testDetailAndLedgerChrome() throws {
        let app = launchApp(reset: true, pseudoLocalized: false)
        brewFromWizard(in: app, expecting: "cellar.beer.1")
        app.buttons["cellar.beer.1"].tap()
        XCTAssertTrue(element("detail", in: app).waitForExistence(timeout: 10))

        // The detail scrolls; check what is on screen at each step.
        for _ in 0..<3 {
            assertTouchTargets(in: app)
            assertNoRawCatalogKeys(in: app)
            dragDetailBody(in: app)
        }

        let citrus = app.buttons["detail.attribute.citrus"]
        XCTAssertTrue(citrus.waitForExistence(timeout: 5))
        citrus.tap()
        XCTAssertTrue(element("ledger.total", in: app).waitForExistence(timeout: 5))
        assertTouchTargets(in: app)
        assertNoRawCatalogKeys(in: app)
        XCTAssertGreaterThanOrEqual(app.buttons["ledger.close"].frame.height, 44)
        assertInThumbZone(app.buttons["ledger.close"], app: app)
    }

    @MainActor
    func testDetailAndLedgerPseudoLocalized() {
        let app = launchApp(reset: true, pseudoLocalized: true)
        // Pseudo-localization doubles every catalog string, so the wizard ids still resolve.
        brewFromWizard(in: app, expecting: "cellar.beer.1")
        app.buttons["cellar.beer.1"].tap()
        let back = app.buttons["detail.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        assertDoubled(back.label)
        attachScreenshot(app, name: "pseudo-detail")

        let citrus = app.buttons["detail.attribute.citrus"]
        XCTAssertTrue(citrus.waitForExistence(timeout: 5))
        citrus.tap()
        let close = app.buttons["ledger.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        assertDoubled(close.label)
        attachScreenshot(app, name: "pseudo-ledger")
    }
}
