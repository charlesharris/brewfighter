import XCTest

/// The share sheet and document picker are OS-owned and are checked by hand; this covers
/// everything the app draws: reaching the sheet and producing a shareable export.
final class SaveTransferUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testExportOffersTheShareButton() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        brewFromWizard(in: app, expecting: "cellar.beer.1")

        let open = app.buttons["cellar.saveTransfer"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()

        let export = app.buttons["saveTransfer.export"]
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["saveTransfer.import"].exists)
        export.tap()

        let share = app.buttons["saveTransfer.share"]
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        XCTAssertTrue(share.isHittable)
    }
}
