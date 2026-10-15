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

    @MainActor
    func testAddHopToAromaSlot() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        let next = app.buttons["wizard.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        next.tap()
        XCTAssertTrue(app.buttons["wizard.stage.boil"].isSelected)

        // The seeded house pale ale has two additions, so the new one lands at index 2.
        tapScrolling(app.buttons["boil.slot.whirlpool"], in: app)
        XCTAssertTrue(app.buttons["boil.slot.whirlpool"].isSelected)
        tapScrolling(app.buttons["boil.card.hop.h04"], in: app)

        XCTAssertTrue(element("boil.additionLine.2", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(element("boil.additionLine.2", in: app).label.contains("Island Haze · Whirlpool"))
        XCTAssertTrue(element("boil.ounces.2", in: app).label.contains("1.00 oz"))

        let plus = app.buttons["boil.step.2.increase"]
        for _ in 0..<3 { tapScrolling(plus, in: app) }
        XCTAssertTrue(element("boil.ounces.2", in: app).label.contains("1.75 oz"))

        app.buttons["wizard.stage.review"].tap()
        let boil = app.buttons["review.panel.boil"]
        XCTAssertTrue(boil.waitForExistence(timeout: 5))
        XCTAssertTrue(boil.label.contains("Island Haze · Whirlpool · 1.75 oz"), boil.label)

        app.buttons["review.brew"].tap()
        XCTAssertTrue(element("cellar.beer.1", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testHoplessBeerIsBrewable() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        XCTAssertTrue(app.buttons["wizard.next"].waitForExistence(timeout: 10))
        app.buttons["wizard.next"].tap()

        // Step every addition down to nothing: 0.75 oz and 1.00 oz are seven taps in all.
        let minus = app.buttons["boil.step.0.decrease"]
        var taps = 0
        while taps < 12 {
            if !element("boil.addition.0", in: app).exists { break }
            tapScrolling(minus, in: app)
            taps += 1
        }
        XCTAssertFalse(element("boil.addition.0", in: app).exists, "all additions removed")
        XCTAssertTrue(element("boil.empty", in: app).exists)

        app.buttons["wizard.stage.review"].tap()
        XCTAssertTrue(app.buttons["review.brew"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["review.brew"].isEnabled, "hops are optional (D-07)")
    }

    @MainActor
    func testFermentChoicesAdvanceDays() {
        let app = launchApp(reset: true, pseudoLocalized: false)
        XCTAssertTrue(app.buttons["wizard.stage.ferment"].waitForExistence(timeout: 10))
        app.buttons["wizard.stage.ferment"].tap()

        // Before a yeast is chosen the real temperatures are unknown; the seeded house yeast is
        // already picked, so choose another one and read its own range.
        tapScrolling(app.buttons["ferment.card.yeast.y03"], in: app)
        XCTAssertTrue(app.buttons["ferment.card.yeast.y03"].isSelected)
        tapScrolling(app.buttons["ferment.temp.cold"], in: app)
        XCTAssertTrue(app.buttons["ferment.temp.cold"].isSelected)
        XCTAssertTrue(app.buttons["ferment.temp.cold"].label.contains("48°F"), app.buttons["ferment.temp.cold"].label)
        tapScrolling(app.buttons["ferment.duration.extended"], in: app)
        XCTAssertTrue(app.buttons["ferment.duration.extended"].isSelected)
        XCTAssertTrue(
            app.buttons["ferment.duration.extended"].label.contains("21 days"),
            app.buttons["ferment.duration.extended"].label)

        app.buttons["wizard.stage.review"].tap()
        let brew = app.buttons["review.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 5))
        brew.tap()

        // Day 1 + 21 days of fermentation + the seeded 3-day dry hop. No waiting step in between.
        let day = element("cellar.day", in: app)
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        XCTAssertTrue(element("cellar.beer.1", in: app).exists, "the beer is in The Cellar immediately")
        XCTAssertEqual(day.label, "Day 25")
    }
}
