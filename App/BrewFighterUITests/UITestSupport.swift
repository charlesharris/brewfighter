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
    /// Frames and identifiers are read once per button: each element property read is a round trip
    /// to the app, so re-reading them inside the pairwise loop makes busy screens take minutes.
    @MainActor
    func assertTouchTargets(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let snapshot = app.buttons.allElementsBoundByIndex.compactMap { button -> (id: String, frame: CGRect)? in
            guard button.exists, button.isHittable else { return nil }
            return (button.identifier, button.frame)
        }
        for item in snapshot {
            XCTAssertGreaterThanOrEqual(item.frame.width, 44, "Button too narrow: \(item.id) \(item.frame)", file: file, line: line)
            XCTAssertGreaterThanOrEqual(item.frame.height, 44, "Button too short: \(item.id) \(item.frame)", file: file, line: line)
        }
        // The wizard's header, stage chips and bottom bar sit outside the scrolling body; a card whose
        // frame is partly scrolled beneath them is clipped, not overlapping. Everything else must not overlap.
        func isWizardChrome(_ id: String) -> Bool { id.hasPrefix("wizard.") || id == "review.brew" }
        for (i, first) in snapshot.enumerated() {
            for second in snapshot.dropFirst(i + 1) {
                if isWizardChrome(first.id) != isWizardChrome(second.id) { continue }
                let a = first.frame.insetBy(dx: 0.5, dy: 0.5)
                let b = second.frame.insetBy(dx: 0.5, dy: 0.5)
                XCTAssertFalse(
                    a.intersects(b),
                    "Buttons overlap: \(first.id) \(first.frame) and \(second.id) \(second.frame)",
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

    /// One controlled drag over the wizard body. `swipeUp()` flings the whole app and can stall the
    /// simulator for minutes; a short press-and-drag moves the content a predictable distance.
    @MainActor
    func dragWizardBody(in app: XCUIApplication, up: Bool) {
        let scroll = app.scrollViews.firstMatch
        let from = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.6 : 0.3))
        let to = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.3 : 0.6))
        from.press(forDuration: 0.05, thenDragTo: to)
    }

    /// True when the element sits fully inside the visible part of the wizard body: below the stage
    /// chips and above the bottom bar. `isHittable` alone is not enough: XCUITest reports buttons that
    /// are partly below the screen edge or under the bottom bar as hittable.
    @MainActor
    func isReachable(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists, element.isHittable else { return false }
        let body = app.scrollViews.firstMatch.frame
        let frame = element.frame
        var bottom = body.maxY
        for id in ["wizard.next", "review.brew", "wizard.back"] {
            let bar = app.buttons[id]
            if bar.exists { bottom = min(bottom, bar.frame.minY - 4) }
        }
        return frame.minY >= body.minY && frame.maxY <= bottom
    }

    /// Scrolls the wizard body until the element is reachable, then taps it.
    @MainActor
    func tapScrolling(_ element: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "missing \(element)", file: file, line: line)
        var attempts = 0
        while !isReachable(element, in: app) && attempts < 8 {
            dragWizardBody(in: app, up: true)
            attempts += 1
        }
        attempts = 0
        while !isReachable(element, in: app) && attempts < 16 {
            dragWizardBody(in: app, up: false)
            attempts += 1
        }
        XCTAssertTrue(isReachable(element, in: app), "could not scroll \(element) into reach", file: file, line: line)
        element.tap()
    }
}
