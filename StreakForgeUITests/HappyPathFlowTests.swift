//
//  HappyPathFlowTests.swift
//  StreakForgeUITests
//
//  One UI test for the spec's "happy path": open app → complete a
//  challenge → verify XP increased.
//

import XCTest

/// XCUITest covering the core action loop.
///
/// We use a *relative* assertion — XP after > XP before — rather than a
/// fixed number, so the test is robust across runs without needing to
/// reset persistent state. (Two consecutive runs: first one bumps XP
/// from 0 to 12; second one bumps from 12 to 24. Both pass the
/// relative check.)
final class HappyPathFlowTests: XCTestCase {

    override func setUpWithError() throws {
        // Stop on first failure so cascading errors don't bury the
        // root cause — debugging UI tests with rolling failures is
        // significantly slower.
        continueAfterFailure = false
    }

    @MainActor
    func testCompleteChallengeIncreasesXP() throws {
        let app = XCUIApplication()
        app.launch()

        // Today is the default tab. The XP pill on ProgressHeader carries
        // an accessibility identifier ("statPillValue.XP") so we can find
        // it without relying on screen position or fragile text matching.
        let xpLabel = app.staticTexts["statPillValue.XP"]
        XCTAssertTrue(
            xpLabel.waitForExistence(timeout: 5),
            "Today's XP pill should appear within 5 seconds of launch"
        )

        let xpBefore = Int(xpLabel.label) ?? -1
        XCTAssertGreaterThanOrEqual(xpBefore, 0, "XP label should parse as a non-negative integer")

        // Find the first Complete button and tap it. The Complete buttons
        // carry their text as an accessibility label by default.
        let completeButtons = app.buttons.matching(identifier: "Complete")
        let firstComplete = completeButtons.firstMatch
        XCTAssertTrue(
            firstComplete.waitForExistence(timeout: 5),
            "At least one pending challenge should be visible on Today"
        )
        firstComplete.tap()

        // After the tap, XP should increase. We wait for the label's
        // value to change (rather than `sleep(_:)`) so the test is as
        // fast as the app allows. Using XCTWaiter directly — earlier I
        // mixed `expectation(for:evaluatedWith:)` with a manual
        // XCTWaiter, which left the auto-tracked expectation unwaited
        // and triggered a hard "unwaited expectation" failure.
        let increased = NSPredicate(
            format: "label != %@",
            String(xpBefore)
        )
        let waitResult = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: increased, object: xpLabel)],
            timeout: 3
        )
        XCTAssertEqual(waitResult, .completed, "XP label should change within 3s of tap")

        let xpAfter = Int(xpLabel.label) ?? -1
        XCTAssertGreaterThan(
            xpAfter, xpBefore,
            "XP after Complete (\(xpAfter)) should exceed XP before (\(xpBefore))"
        )
    }
}
