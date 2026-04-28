//
//  BadgeService.swift
//  StreakForge
//
//  Re-evaluates badge unlocks after each completion. The pure evaluator is
//  separated from SwiftData I/O so it can be tested with hand-rolled
//  snapshots.
//

import Foundation
import SwiftData

// MARK: - Evaluator

/// Pure badge-unlock logic. Takes a `Snapshot` describing the user's
/// current state and returns the set of `BadgeKind`s that should be
/// considered unlocked.
enum BadgeEvaluator {

    /// All the per-user state needed to evaluate every badge. Built by
    /// `BadgeService.makeSnapshot(in:)` from SwiftData; constructed
    /// directly in tests.
    struct Snapshot {

        /// One completed challenge's worth of "when and what" — enough
        /// to evaluate time-of-day and category-based badges.
        struct Completion: Hashable {
            let completedAt: Date
            let category: ChallengeCategory
        }

        let totalCompleted: Int
        let bestStreak: Int
        let completions: [Completion]
    }

    /// Returns every `BadgeKind` whose criterion is satisfied by `snapshot`.
    ///
    /// We return a `Set<BadgeKind>` rather than an array because:
    /// * Order is meaningless (badges aren't ranked).
    /// * Set-difference against the currently-unlocked set is the natural
    ///   way for `BadgeService.apply(...)` to find newly-earned ones.
    static func unlockedKinds(
        snapshot: Snapshot,
        calendar: Calendar = .current
    ) -> Set<BadgeKind> {
        var unlocked: Set<BadgeKind> = []

        // Completion-count badges. Listed top-down so adding more later
        // (e.g. "100 Completed") is a one-line edit.
        if snapshot.totalCompleted >= 1  { unlocked.insert(.firstStep) }
        if snapshot.totalCompleted >= 10 { unlocked.insert(.completed10) }
        if snapshot.totalCompleted >= 25 { unlocked.insert(.completed25) }
        if snapshot.totalCompleted >= 50 { unlocked.insert(.completed50) }

        // Streak badges. We use `bestStreak` (not currentStreak) — once
        // the user has hit a 7-day streak, they keep the badge even if
        // the streak later breaks. That's the standard "achievement"
        // semantic (cf. Strava, Duolingo).
        if snapshot.bestStreak >= 3 { unlocked.insert(.streak3) }
        if snapshot.bestStreak >= 7 { unlocked.insert(.streak7) }

        // Time-of-day badges. We classify by the *user's local* hour at
        // completion time, which is what a user means by "after 10pm".
        // Night Owl: any completion at 22:00 or later.
        if snapshot.completions.contains(where: {
            calendar.component(.hour, from: $0.completedAt) >= 22
        }) {
            unlocked.insert(.nightOwl)
        }
        // Early Bird: any completion strictly before 7:00.
        if snapshot.completions.contains(where: {
            calendar.component(.hour, from: $0.completedAt) < 7
        }) {
            unlocked.insert(.earlyBird)
        }

        // Weekend Warrior: at least one Saturday completion paired with a
        // Sunday completion *the following day* (Sat → Sat+1 = Sun).
        //
        // We deliberately don't group by ISO week here. Calendar week
        // grouping is locale-sensitive — the default Gregorian calendar
        // starts weeks on Sunday, so a Sat-then-Sun pair sits in two
        // different "weeks" and would never satisfy "same week". The
        // badge's intent is "you did a challenge on a Saturday and the
        // following Sunday" — a fact about adjacent calendar days that's
        // independent of any week-numbering convention.
        let saturdayDays: Set<Date> = Set(
            snapshot.completions
                .filter { calendar.component(.weekday, from: $0.completedAt) == 7 }
                .map { calendar.startOfDay(for: $0.completedAt) }
        )
        let sundayDays: Set<Date> = Set(
            snapshot.completions
                .filter { calendar.component(.weekday, from: $0.completedAt) == 1 }
                .map { calendar.startOfDay(for: $0.completedAt) }
        )
        for sat in saturdayDays {
            // Force-unwrap is safe: adding 1 day to a normalized
            // start-of-day cannot fail in any sane calendar.
            let nextDay = calendar.date(byAdding: .day, value: 1, to: sat)!
            if sundayDays.contains(nextDay) {
                unlocked.insert(.weekendWarrior)
                break
            }
        }

        // Category Specialist: 10+ completions in any single category.
        // We count via Dictionary grouping rather than four separate
        // iterations because adding categories later means no extra code.
        let categoryCounts = Dictionary(
            grouping: snapshot.completions, by: \.category
        ).mapValues(\.count)
        if categoryCounts.values.contains(where: { $0 >= 10 }) {
            unlocked.insert(.categorySpecialist)
        }

        return unlocked
    }
}

// MARK: - Service

/// SwiftData-backed wrapper around `BadgeEvaluator`.
struct BadgeService {

    /// Injectable clock — used to stamp `unlockedAt` on newly-earned
    /// badges so tests can assert on a known timestamp.
    var now: () -> Date = { .now }

    /// Re-evaluates every badge against current state and unlocks any
    /// that are newly qualified.
    ///
    /// - Returns: The badges that transitioned from locked → unlocked on
    ///   this call. The view layer uses this to drive the unlock-burst
    ///   animation; an empty array means "nothing changed".
    @discardableResult
    func evaluate(in context: ModelContext) -> [Badge] {
        let snapshot = makeSnapshot(in: context)
        let unlockedKinds = BadgeEvaluator.unlockedKinds(snapshot: snapshot)
        return apply(unlockedKinds, in: context)
    }

    // MARK: Internals

    /// Pulls the data needed by `BadgeEvaluator` out of the store.
    private func makeSnapshot(in context: ModelContext) -> BadgeEvaluator.Snapshot {
        let progress = ProgressService(now: now).current(in: context)

        let allDaily = (try? context.fetch(FetchDescriptor<DailyChallenge>())) ?? []
        let completed = allDaily.filter { $0.status == .completed }

        // Build a templateId → category lookup once, instead of fetching
        // per row. At seed scale (30 templates) the difference is academic;
        // at app scale it would matter.
        let allTemplates = (try? context.fetch(FetchDescriptor<ChallengeTemplate>())) ?? []
        let categoryByTemplateID: [UUID: ChallengeCategory] = Dictionary(
            uniqueKeysWithValues: allTemplates.map { ($0.id, $0.category) }
        )

        let completions: [BadgeEvaluator.Snapshot.Completion] = completed.compactMap { d in
            // A daily must have a `completedAt` and a resolvable template
            // category to be useful for time/category badges. If either
            // is missing we skip — counting it would risk false unlocks.
            guard let when = d.completedAt,
                  let category = categoryByTemplateID[d.templateId] else { return nil }
            return .init(completedAt: when, category: category)
        }

        return BadgeEvaluator.Snapshot(
            totalCompleted: progress.totalCompleted,
            bestStreak: progress.bestStreak,
            completions: completions
        )
    }

    /// Applies the evaluator's verdict to the persisted `Badge` rows,
    /// returning whichever badges flipped from locked to unlocked.
    private func apply(_ kinds: Set<BadgeKind>, in context: ModelContext) -> [Badge] {
        let allBadges = (try? context.fetch(FetchDescriptor<Badge>())) ?? []
        let badgeByID = Dictionary(uniqueKeysWithValues: allBadges.map { ($0.id, $0) })

        var newlyUnlocked: [Badge] = []
        let nowDate = now()

        for kind in kinds {
            guard let badge = badgeByID[kind.id] else {
                // The seed didn't insert this kind for some reason.
                // Skip rather than crash — the next launch's seed will
                // re-attempt insertion.
                continue
            }
            if badge.unlockedAt == nil {
                badge.unlockedAt = nowDate
                newlyUnlocked.append(badge)
            }
        }

        // We deliberately do NOT re-lock badges that the evaluator no
        // longer reports as unlocked. The only way that could happen is
        // via `ProgressService.resetAll`, which handles re-locking
        // explicitly. Persisting unlocks is the badge's whole purpose.

        if !newlyUnlocked.isEmpty {
            try? context.save()
        }

        return newlyUnlocked
    }
}
