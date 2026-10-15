import XCTest

final class BeerDetailUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Brews the pre-seeded house pale ale and opens its detail.
    @MainActor
    private func openHousePaleAleDetail() -> XCUIApplication {
        let app = launchApp(reset: true, pseudoLocalized: false)
        brewFromWizard(in: app, expecting: "cellar.beer.1")
        let row = app.buttons["cellar.beer.1"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(element("detail", in: app).waitForExistence(timeout: 5))
        return app
    }

    /// "+2.5" or "\u{2212}1.0" at the end of a label, in tenths.
    private func trailingSignedTenths(_ label: String) -> Int? {
        guard let match = label.range(of: #"([+−-])(\d+)[.,](\d)$"#, options: .regularExpression) else { return nil }
        let text = String(label[match])
        let sign = text.hasPrefix("+") ? 1 : -1
        let digits = text.dropFirst().filter(\.isNumber)
        return Int(digits).map { $0 * sign }
    }

    private func trailingTenths(_ label: String) -> Int? {
        guard let match = label.range(of: #"(\d+)[.,](\d)$"#, options: .regularExpression) else { return nil }
        return Int(label[match].filter(\.isNumber))
    }

    @MainActor
    func testLedgerRowsSumToTotal() {
        let app = openHousePaleAleDetail()
        XCTAssertTrue(element("detail.title", in: app).label.contains("American Pale Ale"))

        let citrus = app.buttons["detail.attribute.citrus"]
        XCTAssertTrue(citrus.waitForExistence(timeout: 5))
        citrus.tap()
        XCTAssertTrue(element("ledger", in: app).waitForExistence(timeout: 5))
        let totalElement = element("ledger.total", in: app)
        XCTAssertTrue(totalElement.waitForExistence(timeout: 5))

        var sum = 0
        var labels: [String] = []
        var index = 0
        while element("ledger.row.\(index)", in: app).exists {
            let label = element("ledger.row.\(index)", in: app).label
            labels.append(label)
            guard let delta = trailingSignedTenths(label) else {
                XCTFail("Cannot parse ledger row: \(label)")
                return
            }
            sum += delta
            index += 1
        }
        XCTAssertGreaterThan(index, 0, "citrus has contributions on the house pale ale")
        guard let total = trailingTenths(totalElement.label) else {
            XCTFail("Cannot parse total: \(totalElement.label)")
            return
        }
        XCTAssertEqual(sum, total, "rows \(labels) must sum to the total \(totalElement.label)")
        XCTAssertTrue(labels.contains { $0.contains("Solstice") }, "a hop row names its ingredient: \(labels)")

        app.buttons["ledger.close"].tap()
        XCTAssertTrue(app.buttons["detail.back"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEmptyLedger() {
        let app = openHousePaleAleDetail()
        let more = app.buttons["detail.showMore.yeast"]
        if more.waitForExistence(timeout: 2) { more.tap() }
        let funk = app.buttons["detail.attribute.funk"]
        XCTAssertTrue(funk.waitForExistence(timeout: 5))
        XCTAssertTrue(funk.label.contains("0.0"), "funk is zero on the house pale ale: \(funk.label)")
        funk.tap()
        XCTAssertTrue(element("ledger.empty", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(element("ledger.empty", in: app).label.contains("Funk"))
        XCTAssertFalse(element("ledger.row.0", in: app).exists)
    }

    @MainActor
    func testFamiliesPresent() {
        let app = openHousePaleAleDetail()
        var previousY: CGFloat = -1
        for family in ["malt", "hop", "yeast", "mouthfeel"] {
            let panel = element("detail.family.\(family)", in: app)
            XCTAssertTrue(panel.waitForExistence(timeout: 5), "missing family \(family)")
            XCTAssertGreaterThan(panel.frame.minY, previousY, "families appear in order: \(family)")
            previousY = panel.frame.minY
        }
    }

    @MainActor
    func testGlassAndStatsVisible() {
        let app = openHousePaleAleDetail()
        let glass = element("detail.glass", in: app)
        XCTAssertTrue(glass.waitForExistence(timeout: 5))
        XCTAssertTrue(glass.label.contains("American Pale Ale"), "glass label names the style: \(glass.label)")
        for stat in ["abv", "ibu", "srm", "og", "fg"] {
            XCTAssertTrue(element("stats.\(stat)", in: app).exists, "missing stats.\(stat)")
        }
        XCTAssertTrue(element("stats.og", in: app).label.contains("1.050"), element("stats.og", in: app).label)
    }
}
