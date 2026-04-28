//
//  BadgeEvaluatorTests.swift
//  StreakForgeTests
//
//  Pure unit tests for `BadgeEvaluator.unlockedKinds(snapshot:)`.
//

import Testing
import Foundation
@testable import StreakForge

/// Tests for badge unlock evaluation.
///
/// Each test builds a hand-rolled `Snapshot` and asserts which kinds
/// the evaluator returns. We use a fixed Gregorian calendar throughout
/// so weekday-based assertions (Sat=7, Sun=1) hold regardless of the
/// developer's locale.
@Suite("BadgeEvaluator")
struct BadgeEvaluatorTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = hour
        return calendar.date(from: c)!
    }

    // Tiny constructor for snapshot completions.
    private func completion(at d: Date, _ category: ChallengeCategory = .study)
        -> BadgeEvaluator.Snapshot.Completion
    {
        .init(completedAt: d, category: category)
    }

    // MARK: Empty / first

    @Test("Empty snapshot unlocks nothing")
    func emptyUnlocksNothing() {
        let snap = BadgeEvaluator.Snapshot(totalCompleted: 0, bestStreak: 0, completions: [])
        #expect(BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar).isEmpty)
    }

    @Test("First completion unlocks First Step")
    func firstStep() {
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 1, bestStreak: 1,
            completions: [completion(at: date(2026, 4, 28))]
        )
        let r = BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
        #expect(r.contains(.firstStep))
    }

    // MARK: Completion count milestones

    @Test("10 completions unlocks completed10 only (not 25 or 50)")
    func completedTenOnly() {
        let snap = BadgeEvaluator.Snapshot(totalCompleted: 10, bestStreak: 0, completions: [])
        let r = BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
        #expect(r.contains(.firstStep))
        #expect(r.contains(.completed10))
        #expect(!r.contains(.completed25))
        #expect(!r.contains(.completed50))
    }

    @Test("50 completions unlocks all three count milestones")
    func completedFiftyUnlocksAll() {
        let snap = BadgeEvaluator.Snapshot(totalCompleted: 50, bestStreak: 0, completions: [])
        let r = BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
        #expect(r.contains(.completed10))
        #expect(r.contains(.completed25))
        #expect(r.contains(.completed50))
    }

    // MARK: Streak milestones

    @Test("bestStreak >= 3 unlocks streak3")
    func streakThree() {
        let snap = BadgeEvaluator.Snapshot(totalCompleted: 0, bestStreak: 3, completions: [])
        #expect(BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar).contains(.streak3))
    }

    @Test("bestStreak >= 7 unlocks both streak3 and streak7")
    func streakSeven() {
        let snap = BadgeEvaluator.Snapshot(totalCompleted: 0, bestStreak: 7, completions: [])
        let r = BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
        #expect(r.contains(.streak3))
        #expect(r.contains(.streak7))
    }

    @Test("Streak badges use bestStreak — current streak is irrelevant")
    func streakUsesBestNotCurrent() {
        // Snapshot doesn't even carry currentStreak — only bestStreak —
        // which is the test of the rule. Here bestStreak = 3 so streak3
        // unlocks even though "currently" the user might be at 0.
        let snap = BadgeEvaluator.Snapshot(totalCompleted: 5, bestStreak: 3, completions: [])
        #expect(BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar).contains(.streak3))
    }

    // MARK: Time-of-day badges

    @Test("Night Owl unlocks at exactly 22:00")
    func nightOwlAtBoundary() {
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 1, bestStreak: 1,
            completions: [completion(at: date(2026, 4, 28, hour: 22))]
        )
        #expect(BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar).contains(.nightOwl))
    }

    @Test("Night Owl does NOT unlock at 21:59 (boundary check)")
    func nightOwlBelowBoundary() {
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 1, bestStreak: 1,
            // hour: 21 means the completion happened during the 21:00–21:59
            // window — the .hour component returns the integer hour.
            completions: [completion(at: date(2026, 4, 28, hour: 21))]
        )
        #expect(!BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar).contains(.nightOwl))
    }

    @Test("Early Bird unlocks at 06:00")
    func earlyBirdAtSix() {
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 1, bestStreak: 1,
            completions: [completion(at: date(2026, 4, 28, hour: 6))]
        )
        #expect(BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar).contains(.earlyBird))
    }

    @Test("Early Bird does NOT unlock at exactly 07:00 (boundary check)")
    func earlyBirdAtBoundary() {
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 1, bestStreak: 1,
            completions: [completion(at: date(2026, 4, 28, hour: 7))]
        )
        #expect(!BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar).contains(.earlyBird))
    }

    // MARK: Weekend Warrior

    @Test("Sat + Sun in same weekend unlocks Weekend Warrior")
    func weekendSatAndSun() {
        // April 25, 2026 = Saturday, April 26 = Sunday (same ISO week).
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 2, bestStreak: 2,
            completions: [
                completion(at: date(2026, 4, 25)),
                completion(at: date(2026, 4, 26)),
            ]
        )
        #expect(BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
            .contains(.weekendWarrior))
    }

    @Test("Sat-only does NOT unlock Weekend Warrior")
    func weekendSatOnly() {
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 1, bestStreak: 1,
            completions: [completion(at: date(2026, 4, 25))]
        )
        #expect(!BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
            .contains(.weekendWarrior))
    }

    @Test("Sun-only does NOT unlock Weekend Warrior")
    func weekendSunOnly() {
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 1, bestStreak: 1,
            completions: [completion(at: date(2026, 4, 26))]
        )
        #expect(!BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
            .contains(.weekendWarrior))
    }

    // MARK: Category Specialist

    @Test("10 completions in a single category unlocks Category Specialist")
    func categorySpecialistTenInOne() {
        let comps: [BadgeEvaluator.Snapshot.Completion] = (1...10).map {
            completion(at: date(2026, 4, $0), .study)
        }
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 10, bestStreak: 1, completions: comps
        )
        #expect(BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
            .contains(.categorySpecialist))
    }

    @Test("5+5 split across two categories does NOT unlock Category Specialist")
    func categorySpecialistSpread() {
        let study: [BadgeEvaluator.Snapshot.Completion] = (1...5).map {
            completion(at: date(2026, 4, $0), .study)
        }
        let health: [BadgeEvaluator.Snapshot.Completion] = (6...10).map {
            completion(at: date(2026, 4, $0), .health)
        }
        let snap = BadgeEvaluator.Snapshot(
            totalCompleted: 10, bestStreak: 1, completions: study + health
        )
        #expect(!BadgeEvaluator.unlockedKinds(snapshot: snap, calendar: calendar)
            .contains(.categorySpecialist))
    }
}
