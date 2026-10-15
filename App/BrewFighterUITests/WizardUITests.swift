import XCTest

final class WizardUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstRunOpensPreseededWizard() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        XCTAssertTrue(element("wizard", in: app).waitForExistence(timeout: 10))

        app.buttons["wizard.stage.review"].tap()
        let brew = app.buttons["review.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 5))
        XCTAssertTrue(brew.isEnabled, "the house pale ale is brewable as seeded")
        assertInThumbZone(brew, app: app)
        XCTAssertFalse(app.buttons["wizard.next"].exists, "Review hosts BREW instead of Next")
    }

    @MainActor
    func testClearDisablesBrew() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        XCTAssertTrue(app.buttons["wizard.clear"].waitForExistence(timeout: 10))
        app.buttons["wizard.clear"].tap()
        app.buttons["wizard.stage.review"].tap()

        let brew = app.buttons["review.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 5))
        XCTAssertFalse(brew.isEnabled, "an empty recipe has no grain and no yeast")
    }

    @MainActor
    func testFreeNavigation() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let next = app.buttons["wizard.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["wizard.back"].exists, "Back is hidden on the first stage")

        next.tap()
        next.tap()
        app.buttons["wizard.back"].tap()
        XCTAssertTrue(app.buttons["wizard.stage.boil"].isSelected, "Next, Next, Back lands on Boil")

        app.buttons["wizard.stage.mash"].tap()
        XCTAssertTrue(app.buttons["wizard.stage.mash"].isSelected)
        XCTAssertFalse(app.buttons["wizard.back"].exists)
    }

    @MainActor
    func testCellarBrewOpensWizard() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        brewFromWizard(in: app, expecting: "cellar.beer.1")

        app.buttons["cellar.brew"].tap()
        XCTAssertTrue(element("wizard", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["wizard.stage.mash"].isSelected, "the wizard opens on Mash")
    }

    @MainActor
    func testComposeGrainBill() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let clear = app.buttons["wizard.clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 10))
        clear.tap()

        // Empty bill: a specialty cannot start a bill.
        XCTAssertFalse(app.buttons["mash.card.grain.g04"].isEnabled)
        XCTAssertTrue(app.buttons["mash.card.grain.g01"].isEnabled)

        app.buttons["mash.card.grain.g01"].tap()
        XCTAssertTrue(element("mash.total", in: app).label.contains("100"))
        XCTAssertTrue(element("mash.percent.grain.g01", in: app).label.contains("100"))

        app.buttons["mash.card.grain.g04"].tap()
        XCTAssertTrue(element("mash.percent.grain.g01", in: app).label.contains("95"))
        XCTAssertTrue(element("mash.percent.grain.g04", in: app).label.contains("5"))
        XCTAssertTrue(element("mash.total", in: app).label.contains("100"))

        let plus = app.buttons["mash.step.grain.g04.increase"]
        for _ in 0..<3 { plus.tap() }
        XCTAssertTrue(element("mash.percent.grain.g04", in: app).label.contains("20"))
        XCTAssertTrue(element("mash.percent.grain.g01", in: app).label.contains("80"))
        XCTAssertFalse(plus.isEnabled, "Crystal 60 stops at its 20% maximum")

        tapScrolling(app.buttons["mash.strength.strong"], in: app)
        XCTAssertTrue(app.buttons["mash.strength.strong"].isSelected)
        tapScrolling(app.buttons["mash.temp.low"], in: app)
        XCTAssertTrue(app.buttons["mash.temp.low"].isSelected)

        app.buttons["wizard.stage.review"].tap()
        let mash = app.buttons["review.panel.mash"]
        XCTAssertTrue(mash.waitForExistence(timeout: 5))
        XCTAssertTrue(mash.label.contains("Pale Malt 80%"), mash.label)
        XCTAssertTrue(mash.label.contains("Crystal 60 20%"), mash.label)
        XCTAssertTrue(mash.label.contains("Strong"), mash.label)
        XCTAssertTrue(mash.label.contains("Dry & crisp"), mash.label)
        XCTAssertFalse(app.buttons["review.brew"].isEnabled, "Clear also removed the yeast")
    }

    @MainActor
    func testBaseRebalanceAndMakeBase() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        XCTAssertTrue(app.buttons["wizard.clear"].waitForExistence(timeout: 10))
        app.buttons["wizard.clear"].tap()

        app.buttons["mash.card.grain.g01"].tap()
        app.buttons["mash.card.grain.g02"].tap()
        XCTAssertTrue(element("mash.percent.grain.g02", in: app).label.contains("5"))

        // At 5% the pilsner malt would leave the base too thin, so the rules refuse the swap.
        XCTAssertFalse(app.buttons["mash.makeBase.grain.g02"].isEnabled)
        app.buttons["mash.step.grain.g02.increase"].tap()
        XCTAssertTrue(app.buttons["mash.makeBase.grain.g02"].isEnabled)

        // A base-capable entry can take over the base role; percents stay put.
        app.buttons["mash.makeBase.grain.g02"].tap()
        XCTAssertTrue(app.buttons["mash.makeBase.grain.g01"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["mash.makeBase.grain.g02"].exists)
        XCTAssertTrue(element("mash.percent.grain.g01", in: app).label.contains("90"))

        // Removing a specialty returns its percent to the base.
        app.buttons["mash.remove.grain.g01"].tap()
        XCTAssertTrue(element("mash.percent.grain.g02", in: app).label.contains("100"))
    }
}
