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

        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))
        brew.tap()

        let beer = app.descendants(matching: .any)["cellar.beer.1"]
        XCTAssertTrue(beer.waitForExistence(timeout: 5))
        let dayBefore = app.staticTexts["cellar.day"].label

        app.terminate()

        let relaunched = XCUIApplication()
        relaunched.launch()
        XCTAssertTrue(relaunched.descendants(matching: .any)["cellar.beer.1"].waitForExistence(timeout: 10))
        XCTAssertEqual(relaunched.staticTexts["cellar.day"].label, dayBefore)
    }
}
