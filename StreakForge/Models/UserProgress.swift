//
//  UserProgress.swift
//  StreakForge
//
//  The user's running totals — XP, streaks, completion count, settings.
//

import Foundation
import SwiftData

/// The single per-user state row.
///
/// Conceptually a singleton: there is exactly one `UserProgress` record per
/// install. The "fetch-or-create" lookup is owned by `ProgressService`
/// (added in Step 4); model code stays pure data.
///
/// All counters live on this one row (rather than scattered across keys in
/// `UserDefaults`) so they participate in SwiftData's transaction model —
/// awarding XP, bumping the streak, and updating `lastCompletionDate` all
/// commit atomically, which is important because a partial commit could
/// leave the streak counter and last-completion date out of sync.
@Model
final class UserProgress {

    // MARK: Cumulative totals

    /// Lifetime XP. Starts at 0; only ever increases.
    var totalXP: Int

    /// Number of consecutive days with at least one completion, ending at
    /// `lastCompletionDate`. Reset to 1 when the chain breaks (i.e. when a
    /// completion lands on a day that is *not* the day after
    /// `lastCompletionDate`).
    var currentStreak: Int

    /// The longest `currentStreak` ever achieved. Updated whenever
    /// `currentStreak` exceeds it. Never decreases.
    var bestStreak: Int

    /// The date (start-of-day) of the user's most recent completion.
    /// `nil` until they complete their first challenge — distinguishing
    /// "never completed" from "completed today" is required by the
    /// streak rule, hence the optional rather than a sentinel like
    /// `.distantPast`.
    var lastCompletionDate: Date?

    /// Lifetime number of completed challenges. Used by the "10 / 25 / 50
    /// Completed" badges. Strictly redundant with the History query
    /// (`count where status == .completed`) but caching it on this row
    /// avoids running that aggregate every time a badge re-evaluates.
    var totalCompleted: Int

    // MARK: Swap budget

    /// How many swaps the user has used today. The spec caps this at 1.
    /// Stored explicitly (rather than derived from a "did I swap today?"
    /// boolean) so the cap can be tuned per day later without a migration.
    var swapsUsedToday: Int

    /// The day the swap counter was last reset to 0 (start-of-day).
    /// `ChallengeService.swap(...)` checks this on every call: if it
    /// doesn't match today, the counter is reset before the swap proceeds.
    /// Storing the date — not just relying on a midnight scheduled task —
    /// keeps the reset correct even if the app was closed across midnight.
    var swapsResetDate: Date

    // MARK: Settings

    /// Time of day the daily reminder fires. Only the hour and minute
    /// components are meaningful; the date portion is ignored by
    /// `NotificationService`. Defaulted to 9:00 AM in the init.
    ///
    /// We use `Date` instead of `DateComponents` because SwiftData
    /// persists `Date` natively, and `DatePicker` (used in Settings)
    /// binds to `Date` directly — no conversion glue needed.
    var notificationTime: Date

    // MARK: Init

    /// Designated initializer. All counters default to a fresh-install
    /// state so callers can simply `UserProgress()` to create the first
    /// row without specifying anything.
    init(
        totalXP: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        lastCompletionDate: Date? = nil,
        totalCompleted: Int = 0,
        swapsUsedToday: Int = 0,
        swapsResetDate: Date = Calendar.current.startOfDay(for: .now),
        notificationTime: Date = UserProgress.defaultNotificationTime()
    ) {
        self.totalXP = totalXP
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastCompletionDate = lastCompletionDate
        self.totalCompleted = totalCompleted
        self.swapsUsedToday = swapsUsedToday
        self.swapsResetDate = swapsResetDate
        self.notificationTime = notificationTime
    }

    /// Builds the default reminder time (9:00 AM today). Pulled into a
    /// helper because the default literal would otherwise have to live
    /// in the parameter list, and SwiftData's macro expansion doesn't
    /// always cope well with non-trivial default expressions there.
    private static func defaultNotificationTime() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 9
        comps.minute = 0
        // Force-unwrap is safe: we just supplied year/month/day from the
        // current date, plus a valid hour/minute — `date(from:)` cannot
        // fail unless the calendar itself is broken.
        return Calendar.current.date(from: comps)!
    }
}
