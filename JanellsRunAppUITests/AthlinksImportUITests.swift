import XCTest

final class AthlinksImportUITests: XCTestCase {
    private let shotDir = ProcessInfo.processInfo.environment["SHOT_DIR"] ?? NSTemporaryDirectory()

    func testAthlinksImportFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Add"].tap()
        let athlinksSegment = app.buttons["Athlinks"]
        XCTAssertTrue(athlinksSegment.waitForExistence(timeout: 5), "Athlinks segment missing")
        athlinksSegment.tap()
        snap(app, "01-lookup-empty")

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("https://www.athlinks.com/athletes/410409327/results")
        snap(app, "02-lookup-filled")

        app.buttons["Load Results"].tap()

        let header = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'new result'")).firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 40), "Results never loaded")
        let headerText = header.label
        snap(app, "03-results-top")

        app.swipeUp()
        app.swipeUp()
        snap(app, "04-results-scrolled")
        app.swipeDown()
        app.swipeDown()

        let importButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Import'")).firstMatch
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))
        let importLabel = importButton.label
        importButton.tap()

        snap(app, "05-after-import")
        let afterImport = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'new result' OR label CONTAINS 'Imported' OR label CONTAINS 'already'")).firstMatch
        _ = afterImport.waitForExistence(timeout: 5)
        let afterText = afterImport.exists ? afterImport.label : "(none)"

        app.tabBars.buttons["Races"].tap()
        sleep(1)
        snap(app, "06-races")

        app.tabBars.buttons["PRs"].tap()
        sleep(1)
        snap(app, "07-prs")

        app.tabBars.buttons["Add"].tap()
        app.buttons["Athlinks"].tap()
        sleep(1)
        snap(app, "08-athlinks-again")

        let summary = "header=\(headerText) | import=\(importLabel) | after=\(afterText)"
        let note = XCTAttachment(string: summary)
        note.name = "summary"
        note.lifetime = .keepAlways
        add(note)
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let path = (shotDir as NSString).appendingPathComponent("\(name).png")
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: path))
    }
}
