import XCTest

final class PersistenceUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testBrewedBeerSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestResetSave"]
        app.launch()

        // First launch with an empty cellar opens the pre-seeded wizard (D-06).
        XCTAssertTrue(element("wizard", in: app).waitForExistence(timeout: 10))
        brewFromWizard(in: app, expecting: "cellar.beer.1")
        let dayBefore = app.staticTexts["cellar.day"].label

        app.terminate()

        let relaunched = XCUIApplication()
        relaunched.launch()
        XCTAssertTrue(element("cellar.beer.1", in: relaunched).waitForExistence(timeout: 10))
        XCTAssertEqual(relaunched.staticTexts["cellar.day"].label, dayBefore)
        // With a beer in the cellar the app opens on The Cellar, not the wizard.
        XCTAssertTrue(relaunched.buttons["cellar.brew"].exists)
        XCTAssertFalse(element("wizard", in: relaunched).exists)
    }
}
