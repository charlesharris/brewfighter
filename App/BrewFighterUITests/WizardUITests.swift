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
}
