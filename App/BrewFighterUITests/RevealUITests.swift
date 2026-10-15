import XCTest

final class RevealUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Resets, opens Review on the pre-seeded house pale ale and taps BREW.
    @MainActor
    private func startBrewing() -> XCUIApplication {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let review = app.buttons["wizard.stage.review"]
        XCTAssertTrue(review.waitForExistence(timeout: 10), "wizard did not open")
        review.tap()
        let brew = app.buttons["review.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 5))
        brew.tap()
        return app
    }

    @MainActor
    func testSkipJumpsToFinalState() {
        let app = startBrewing()
        XCTAssertTrue(element("reveal", in: app).waitForExistence(timeout: 5))
        let skip = app.buttons["reveal.skip"]
        XCTAssertTrue(skip.exists, "Skip is offered while the reveal plays")
        skip.tap()

        let toCellar = app.buttons["reveal.toCellar"]
        XCTAssertTrue(toCellar.waitForExistence(timeout: 2), "Skip lands on the final card at once")
        XCTAssertTrue(toCellar.isHittable)
        XCTAssertTrue(app.buttons["reveal.details"].isHittable)
        XCTAssertFalse(app.buttons["reveal.skip"].exists, "Skip is gone on the final card")
        let style = element("reveal.style", in: app)
        XCTAssertTrue(style.exists)
        XCTAssertEqual(style.label, "American Pale Ale")
        XCTAssertEqual(element("reveal.day", in: app).label, "Day 18")
    }

    @MainActor
    func testRevealPlaysToCompletionWithoutSkip() {
        let app = startBrewing()
        XCTAssertTrue(element("reveal", in: app).waitForExistence(timeout: 5))
        let started = Date()
        // About 3.4 s of animation; the generous timeout only absorbs simulator slowness.
        XCTAssertTrue(app.buttons["reveal.details"].waitForExistence(timeout: 10), "the reveal never finished")
        XCTAssertLessThan(Date().timeIntervalSince(started), 9)
        app.buttons["reveal.details"].tap()
        XCTAssertTrue(element("detail", in: app).waitForExistence(timeout: 5), "See the details opens the beer")
    }

    @MainActor
    func testForceQuitMidRevealKeepsBeerOnce() {
        let app = startBrewing()
        XCTAssertTrue(element("reveal", in: app).waitForExistence(timeout: 5))
        app.terminate()

        let relaunched = launchApp(reset: false, pseudoLocalized: false)
        XCTAssertTrue(element("cellar.beer.1", in: relaunched).waitForExistence(timeout: 10), "the beer was saved before the reveal")
        XCTAssertFalse(element("cellar.beer.2", in: relaunched).exists, "the brew is not counted twice")
        // 1 + the house pale ale's 17 days (14 fermenting + 3 dry hop), advanced exactly once.
        XCTAssertEqual(relaunched.staticTexts["cellar.day"].label, "Day 18")
        XCTAssertFalse(element("reveal", in: relaunched).exists, "a relaunch lands on The Cellar")
    }
}
