import XCTest

/// Shared UI-test helpers. Later UI plans reuse these to enforce the 44pt touch-target floor,
/// catch catalog keys that render raw, and exercise pseudo-localization.
extension XCTestCase {
    /// Launches the app. `reset` wipes the save (DEBUG-only flag); `pseudoLocalized` doubles
    /// every catalog string so hard-coded text and broken format strings stand out.
    @MainActor
    @discardableResult
    func launchApp(reset: Bool, pseudoLocalized: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        if reset { app.launchArguments += ["-UITestResetSave"] }
        if pseudoLocalized { app.launchArguments += ["-NSDoubleLocalizedStrings", "YES"] }
        app.launch()
        return app
    }

    /// Every hittable button is at least 44x44pt and no two hittable buttons overlap.
    @MainActor
    func assertTouchTargets(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let hittable = app.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
        for button in hittable {
            let frame = button.frame
            XCTAssertGreaterThanOrEqual(frame.width, 44, "Button too narrow: \(button.debugDescription)", file: file, line: line)
            XCTAssertGreaterThanOrEqual(frame.height, 44, "Button too short: \(button.debugDescription)", file: file, line: line)
        }
        for (i, first) in hittable.enumerated() {
            for second in hittable.dropFirst(i + 1) {
                let a = first.frame.insetBy(dx: 0.5, dy: 0.5)
                let b = second.frame.insetBy(dx: 0.5, dy: 0.5)
                XCTAssertFalse(
                    a.intersects(b),
                    "Buttons overlap: \(first.identifier) \(first.frame) and \(second.identifier) \(second.frame)",
                    file: file, line: line)
            }
        }
    }

    /// A missing catalog key renders as its dotted identifier; no static text may look like one.
    @MainActor
    func assertNoRawCatalogKeys(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let rawKey = #"^[a-z][A-Za-z0-9]*(\.[A-Za-z0-9_]+)+"#
        for text in app.staticTexts.allElementsBoundByIndex where text.exists {
            let label = text.label
            XCTAssertNil(
                label.range(of: rawKey, options: .regularExpression),
                "Raw catalog key on screen: \(label)", file: file, line: line)
        }
    }

    /// The element sits in the lower 40% of the window (one-handed reach).
    @MainActor
    func assertInThumbZone(_ element: XCUIElement, app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let windowHeight = app.windows.firstMatch.frame.height
        XCTAssertGreaterThanOrEqual(
            element.frame.minY, 0.6 * windowHeight,
            "\(element.identifier) is above the thumb zone", file: file, line: line)
    }

    /// Under -NSDoubleLocalizedStrings a catalog string renders as "X X".
    func assertDoubled(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let chars = Array(label)
        let isDoubled = chars.count >= 3 && chars.count % 2 == 1
            && chars[chars.count / 2] == " "
            && chars[..<(chars.count / 2)] == chars[(chars.count / 2 + 1)...]
        XCTAssertTrue(isDoubled, "Not pseudo-localized (expected \"X X\"): \(label)", file: file, line: line)
    }

    @MainActor
    func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The element with this accessibility identifier, of any type.
    @MainActor
    func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// First-run launches land on the pre-seeded wizard (D-06). Closes it to reach The Cellar.
    @MainActor
    func closeWizardToCellar(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let close = app.buttons["wizard.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10), "wizard did not open", file: file, line: line)
        close.tap()
        XCTAssertTrue(app.buttons["cellar.brew"].waitForExistence(timeout: 5), file: file, line: line)
    }

    /// Brews whatever the wizard currently holds: jump to Review, tap BREW, wait for the cellar.
    @MainActor
    func brewFromWizard(in app: XCUIApplication, expecting beer: String, file: StaticString = #filePath, line: UInt = #line) {
        let review = app.buttons["wizard.stage.review"]
        XCTAssertTrue(review.waitForExistence(timeout: 10), "wizard did not open", file: file, line: line)
        review.tap()
        let brew = app.buttons["review.brew"]
        XCTAssertTrue(brew.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(brew.isEnabled, "BREW should be enabled", file: file, line: line)
        brew.tap()
        XCTAssertTrue(element(beer, in: app).waitForExistence(timeout: 5), file: file, line: line)
    }
}
