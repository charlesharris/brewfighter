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
        let brew = app.buttons["cellar.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 10))
        brew.tap()
        XCTAssertTrue(app.descendants(matching: .any)["cellar.beer.1"].waitForExistence(timeout: 5))

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
