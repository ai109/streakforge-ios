//
//  StreakCalculatorTests.swift
//  StreakForgeTests
//
//  Pure unit tests for `StreakCalculator.update(...)`. No SwiftData
//  container needed — the algorithm is a pure function.
//

import Testing
import Foundation
@testable import StreakForge

/// Tests for the streak update rule.
///
/// All tests use a fixed Gregorian calendar (not `Calendar.current`) so
/// behavior doesn't drift if the developer's locale or first-day-of-week
/// changes. The dates are constructed via the `date(_:_:_:hour:)` helper
/// so each test reads as a literal calendar date.
@Suite("StreakCalculator")
struct StreakCalculatorTests {

    // Fixed Gregorian calendar — tests must not depend on the test
    // runner's locale.
    private let calendar = Calendar(identifier: .gregorian)

    /// Quick date constructor. Force-unwrap is fine — every literal we
    /// pass is a valid calendar date, and a malformed test input is the
    /// kind of bug we'd want a crash for.
    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = y
        c.month = m
        c.day = d
        c.hour = hour
        return calendar.date(from: c)!
    }

    @Test("First completion ever starts streak at 1")
    func firstCompletionStartsAtOne() {
        let result = StreakCalculator.update(
            currentStreak: 0,
            lastCompletionDate: nil,
            completionDate: date(2026, 4, 28),
            calendar: calendar
        )
        #expect(result.newStreak == 1)
        // Returned date must be normalized to start-of-day so subsequent
        // comparisons are exact.
        #expect(result.newLastDate == date(2026, 4, 28, hour: 0))
    }

    @Test("Same calendar day does not bump the streak")
    func sameDayDoesNotBump() {
        let result = StreakCalculator.update(
            currentStreak: 5,
            lastCompletionDate: date(2026, 4, 28, hour: 9),
            completionDate: date(2026, 4, 28, hour: 18),
            calendar: calendar
        )
        #expect(result.newStreak == 5)
    }

    @Test("Consecutive day continues the streak (+1)")
    func consecutiveDayContinues() {
        let result = StreakCalculator.update(
            currentStreak: 5,
            lastCompletionDate: date(2026, 4, 27),
            completionDate: date(2026, 4, 28),
            calendar: calendar
        )
        #expect(result.newStreak == 6)
    }

    @Test("Gap of 2+ days resets the streak to 1")
    func gapResetsToOne() {
        let result = StreakCalculator.update(
            currentStreak: 5,
            lastCompletionDate: date(2026, 4, 25),
            completionDate: date(2026, 4, 28),
            calendar: calendar
        )
        #expect(result.newStreak == 1)
    }

    @Test("Hour of day is ignored — 23:59 → 00:01 next day still consecutive")
    func midnightCrossingIsConsecutive() {
        // The user finishes a challenge at 11:59 PM, then another at
        // 12:01 AM the next day. The day-boundary semantics mean these
        // are *consecutive*, not "same day".
        let result = StreakCalculator.update(
            currentStreak: 3,
            lastCompletionDate: date(2026, 4, 27, hour: 23),
            completionDate: date(2026, 4, 28, hour: 0),
            calendar: calendar
        )
        #expect(result.newStreak == 4)
    }

    @Test("Long gap from year-old completion still resets to 1")
    func ancientLastCompletionResets() {
        let result = StreakCalculator.update(
            currentStreak: 99,
            lastCompletionDate: date(2025, 1, 1),
            completionDate: date(2026, 4, 28),
            calendar: calendar
        )
        #expect(result.newStreak == 1)
    }
}
