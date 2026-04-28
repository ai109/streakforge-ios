//
//  XPCalculatorTests.swift
//  StreakForgeTests
//
//  Pure unit tests for `XPCalculator.awardedXP(...)`.
//

import Testing
@testable import StreakForge

/// Tests for the XP award formula.
///
/// Per the spec: `base + min(currentStreak * 2, 20)` where base is
/// 10 / 20 / 35 for easy / medium / hard. We use the *post-update*
/// streak — see `XPCalculator.awardedXP`'s doc comment for why.
@Suite("XPCalculator")
struct XPCalculatorTests {

    // MARK: Base values

    @Test("Easy at streak 0 → 10 XP")
    func easyBase() {
        #expect(XPCalculator.awardedXP(difficulty: .easy, currentStreak: 0) == 10)
    }

    @Test("Medium at streak 0 → 20 XP")
    func mediumBase() {
        #expect(XPCalculator.awardedXP(difficulty: .medium, currentStreak: 0) == 20)
    }

    @Test("Hard at streak 0 → 35 XP")
    func hardBase() {
        #expect(XPCalculator.awardedXP(difficulty: .hard, currentStreak: 0) == 35)
    }

    // MARK: Streak bonus

    @Test("First completion (streak=1) gets +2 bonus")
    func firstCompletionBonus() {
        // Per the post-update-streak rule, streak goes 0→1 on first
        // completion, so the awarded XP includes the +2 bonus.
        #expect(XPCalculator.awardedXP(difficulty: .easy, currentStreak: 1) == 12)
    }

    @Test("Bonus scales linearly: streak=5 → +10")
    func linearBonus() {
        #expect(XPCalculator.awardedXP(difficulty: .easy, currentStreak: 5) == 20)
        #expect(XPCalculator.awardedXP(difficulty: .medium, currentStreak: 3) == 26)
        #expect(XPCalculator.awardedXP(difficulty: .hard, currentStreak: 7) == 49)
    }

    // MARK: Cap

    @Test("Bonus caps at +20 (streak=10 hits the cap exactly)")
    func bonusCapAtTen() {
        // streak 10 × 2 = 20 → exactly the cap.
        #expect(XPCalculator.awardedXP(difficulty: .easy, currentStreak: 10) == 30)
        #expect(XPCalculator.awardedXP(difficulty: .hard, currentStreak: 10) == 55)
    }

    @Test("Bonus stays at +20 for streaks beyond 10")
    func bonusStaysCapped() {
        // streak 15, 50, 1000 — bonus is still +20.
        #expect(XPCalculator.awardedXP(difficulty: .easy, currentStreak: 15) == 30)
        #expect(XPCalculator.awardedXP(difficulty: .easy, currentStreak: 50) == 30)
        #expect(XPCalculator.awardedXP(difficulty: .hard, currentStreak: 1000) == 55)
    }

    // MARK: Defensive

    @Test("Negative streak treated as zero (no negative bonus)")
    func negativeStreakSafe() {
        // Should never happen in practice, but the formula's `max(_, 0)`
        // floor protects us. A naive `streak * 2` would yield a *negative*
        // bonus and undercut the base XP — actively harmful behavior.
        #expect(XPCalculator.awardedXP(difficulty: .easy, currentStreak: -1) == 10)
        #expect(XPCalculator.awardedXP(difficulty: .hard, currentStreak: -100) == 35)
    }
}
