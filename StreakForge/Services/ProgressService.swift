//
//  ProgressService.swift
//  StreakForge
//
//  Owns the streak/XP/totals math and the persistence side-effects on
//  `UserProgress`. Pure algorithms live up top so they can be unit-tested
//  in isolation; the wrapper service glues them to SwiftData.
//

import Foundation
import SwiftData

// MARK: - XP

/// Pure XP calculation. Independent of SwiftData; testable directly.
enum XPCalculator {

    /// XP awarded for one completion.
    ///
    /// Per the spec: `base difficulty XP + min(currentStreak * 2, 20)`.
    ///
    /// ## Why we use the *post-update* streak
    ///
    /// The spec's wording ("streak bonus of +2 XP per current-streak day")
    /// is genuinely ambiguous about whether `currentStreak` is the value
    /// before or after this completion is counted. We use the post-update
    /// value because:
    /// * It rewards the first-ever completion with a small +2 bonus
    ///   (streak goes 0→1, bonus = 2). The pre-update reading would award
    ///   no bonus, which feels punitive on day one.
    /// * It makes the bonus monotonically non-decreasing day-over-day
    ///   when the streak is preserved — the user always sees a number
    ///   that "rewards their streak today".
    static func awardedXP(difficulty: ChallengeDifficulty, currentStreak: Int) -> Int {
        // `max(0, …)` guards against any caller passing a negative streak
        // (shouldn't happen, but cheap insurance against a future bug
        // turning an Int into something weird like `-1` as a sentinel).
        let bonus = min(max(currentStreak, 0) * 2, 20)
        return difficulty.baseXP + bonus
    }
}

// MARK: - Streak

/// Pure streak update logic. Returns the new streak and the new
/// last-completion date for a given completion event.
enum StreakCalculator {

    /// Result of evaluating one completion against the running streak.
    struct Result: Equatable {
        let newStreak: Int
        let newLastDate: Date
    }

    /// Computes the streak update for a completion happening at
    /// `completionDate`.
    ///
    /// Rules (from the spec, strict — no grace day):
    /// * `lastCompletionDate == nil`              → streak = 1.
    /// * `lastCompletionDate == today`            → unchanged (multi-completes
    ///                                              in one day don't double-count).
    /// * `lastCompletionDate == yesterday`        → streak += 1.
    /// * anything else (gap of 1+ full days)      → streak resets to 1.
    /// In every case `newLastDate` is normalized to the start of the
    /// completion's day so subsequent comparisons are exact.
    static func update(
        currentStreak: Int,
        lastCompletionDate: Date?,
        completionDate: Date,
        calendar: Calendar = .current
    ) -> Result {
        // Normalize both sides to start-of-day so the comparisons below are
        // calendar-day equality, not wall-clock instant equality.
        let today = calendar.startOfDay(for: completionDate)

        // First-ever completion: streak begins.
        guard let last = lastCompletionDate else {
            return Result(newStreak: 1, newLastDate: today)
        }

        let lastNorm = calendar.startOfDay(for: last)

        // Same calendar day: nothing changes. The user has already had
        // their streak bumped by an earlier completion today.
        if lastNorm == today {
            return Result(newStreak: currentStreak, newLastDate: today)
        }

        // Force-unwrap: adding -1 day to a normalized date can only fail
        // if the calendar itself is malformed. Acceptable.
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Consecutive day: streak continues.
        if lastNorm == yesterday {
            return Result(newStreak: currentStreak + 1, newLastDate: today)
        }

        // Gap of 1+ full days: chain broken, restart at 1 (this completion
        // is the new day-one of a fresh streak).
        return Result(newStreak: 1, newLastDate: today)
    }
}

// MARK: - Service

/// SwiftData-backed wrapper that holds the singleton `UserProgress` row
/// and applies the pure algorithms above to it.
struct ProgressService {

    /// Injectable clock. Real callers leave the default; tests pass a
    /// fixed-date closure so streak edge-cases are deterministic.
    var now: () -> Date = { .now }

    // MARK: Singleton access

    /// Returns the singleton `UserProgress`, creating it on first call.
    ///
    /// Centralizing the fetch-or-create here means no other code needs to
    /// worry about whether the row exists — every service that needs
    /// progress just calls `current(in:)` and gets a guaranteed instance.
    func current(in context: ModelContext) -> UserProgress {
        let descriptor = FetchDescriptor<UserProgress>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let fresh = UserProgress()
        context.insert(fresh)
        // Save eagerly so a crash between insert and the next save can't
        // leave us without a progress row (which would force a second
        // insert next launch, and SwiftData would happily create two).
        try? context.save()
        return fresh
    }

    // MARK: Mutations

    /// Records a completion: marks the challenge done, updates the streak,
    /// awards XP, bumps `totalCompleted`, and saves.
    ///
    /// Returns the XP awarded so the UI can drive its count-up animation.
    @discardableResult
    func recordCompletion(
        of challenge: DailyChallenge,
        difficulty: ChallengeDifficulty,
        in context: ModelContext
    ) -> Int {
        let nowDate = now()
        let progress = current(in: context)

        // Update streak first so XP is computed against the *new* streak
        // value (see `XPCalculator.awardedXP`'s doc comment for why).
        let result = StreakCalculator.update(
            currentStreak: progress.currentStreak,
            lastCompletionDate: progress.lastCompletionDate,
            completionDate: nowDate
        )
        progress.currentStreak = result.newStreak
        progress.lastCompletionDate = result.newLastDate

        // Best-streak only goes up. We update it inline (rather than as a
        // separate "evaluate best" pass) because it's a single comparison.
        if result.newStreak > progress.bestStreak {
            progress.bestStreak = result.newStreak
        }

        progress.totalCompleted += 1

        let xp = XPCalculator.awardedXP(
            difficulty: difficulty,
            currentStreak: result.newStreak
        )
        progress.totalXP += xp

        // Mark the challenge itself.
        challenge.status = .completed
        challenge.completedAt = nowDate

        try? context.save()
        return xp
    }

    /// Records a skip: marks the challenge skipped. No XP, no streak
    /// change, no `totalCompleted` bump — skipping is a deliberate "not
    /// today" rather than a failure or success.
    func recordSkip(of challenge: DailyChallenge, in context: ModelContext) {
        challenge.status = .skipped
        try? context.save()
    }

    /// Resets the daily swap budget if the calendar day has changed since
    /// the last reset. Called by `ChallengeService.swap` (so a swap in a
    /// stale state behaves correctly) and by `TodayViewModel.bootstrap`
    /// (so the UI's "1 swap remaining" counter rolls over before any
    /// action is taken).
    ///
    /// Pulling this into a single helper means the rule "midnight rolls
    /// the budget" is enforced in exactly one place — no chance of
    /// `swap` and the UI disagreeing about whether a swap is available.
    func resetSwapBudgetIfNeeded(in context: ModelContext) {
        let today = Calendar.current.startOfDay(for: now())
        let progress = current(in: context)
        guard progress.swapsResetDate != today else { return }
        progress.swapsUsedToday = 0
        progress.swapsResetDate = today
        try? context.save()
    }

    // MARK: Reset

    /// Wipes the user's progress: deletes every `DailyChallenge`, resets
    /// the `UserProgress` counters, and re-locks every badge. Templates
    /// and badge definitions themselves are preserved.
    ///
    /// Used by Settings → Reset Progress (with a confirmation dialog at
    /// the call site — this method does *not* prompt).
    func resetAll(in context: ModelContext) {
        if let dailies = try? context.fetch(FetchDescriptor<DailyChallenge>()) {
            for d in dailies { context.delete(d) }
        }

        let progress = current(in: context)
        progress.totalXP = 0
        progress.currentStreak = 0
        progress.bestStreak = 0
        progress.lastCompletionDate = nil
        progress.totalCompleted = 0
        progress.swapsUsedToday = 0
        progress.swapsResetDate = Calendar.current.startOfDay(for: now())
        // Notification time is intentionally preserved — the user's
        // preferred reminder time isn't progress, it's a setting.

        if let badges = try? context.fetch(FetchDescriptor<Badge>()) {
            for b in badges { b.unlockedAt = nil }
        }

        try? context.save()
    }
}
