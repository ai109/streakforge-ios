//
//  StatsData.swift
//  StreakForge
//
//  Pure computation that turns raw `DailyChallenge` and `ChallengeTemplate`
//  arrays into the aggregates the Stats screen renders. Lives outside any
//  view so unit tests can drive it with hand-built fixtures.
//

import Foundation

/// All the numbers the Stats screen needs in one value type.
///
/// Built once per render via `StatsData.compute(...)`. Keeping the
/// computation in a static function (rather than baking it into a
/// view-model) means the Stats view can stay `@Query`-driven — every
/// SwiftData mutation triggers a re-render which triggers a re-compute,
/// and we never have to remember to "refresh" anything.
struct StatsData: Equatable {

    /// One bar in the activity chart.
    struct DailyCount: Identifiable, Equatable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    /// One row in the per-category breakdown.
    struct CategoryCount: Identifiable, Equatable {
        let category: ChallengeCategory
        let count: Int
        var id: ChallengeCategory { category }
    }

    /// Lifetime completed count. (Distinct from `periodCount` below.)
    let totalCompleted: Int

    /// Lifetime skipped count. Used in `completionRate`'s denominator.
    let totalSkipped: Int

    /// completed / (completed + skipped). 0 when the user hasn't acted on
    /// any challenges yet — `0%` is the honest answer there, not `nil`.
    /// Pending challenges are deliberately *excluded* from the denominator
    /// — the rate is "of the challenges I've decided about, what fraction
    /// did I do?", not "of every challenge I was ever offered".
    let completionRate: Double

    /// Completed count within the selected `days` window, ending today.
    /// Mirrors the sum of `dailyCompletions[*].count`.
    let periodCount: Int

    /// Per-day series for the activity chart. Always exactly `days` long
    /// — missing days are zero-filled so the bar chart's x-axis is
    /// continuous (no gaps where the user took a day off).
    let dailyCompletions: [DailyCount]

    /// Per-category aggregates. Always `ChallengeCategory.allCases.count`
    /// long, in `allCases` order, even for zero-count categories — keeps
    /// the breakdown layout stable and makes "I haven't done any
    /// Mindfulness yet" visible at a glance.
    let categoryCompletions: [CategoryCount]

    /// Computes a fresh snapshot from the raw row arrays.
    ///
    /// - Parameters:
    ///   - challenges: All `DailyChallenge` rows in the store.
    ///   - templates:  All `ChallengeTemplate` rows in the store. Needed
    ///                 only to map a daily's `templateId` → category.
    ///   - days:       Width of the activity-chart window. The Stats
    ///                 screen passes 7 (week view) or 30 (month view).
    ///   - now:        Reference date for "today". Injectable so tests
    ///                 can pin it.
    ///   - calendar:   Same — injectable for tests / non-Gregorian users.
    static func compute(
        challenges: [DailyChallenge],
        templates: [ChallengeTemplate],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> StatsData {

        let completed = challenges.filter { $0.status == .completed }
        let skipped   = challenges.filter { $0.status == .skipped }
        let attempted = completed.count + skipped.count

        // 0 attempts → 0%. We use 0 (not nil / NaN / undefined) so the UI
        // can render the gauge unconditionally; an empty-state branch
        // higher up already handles the "literally no data" case.
        let completionRate = attempted > 0
            ? Double(completed.count) / Double(attempted)
            : 0

        // MARK: Daily series

        let today = calendar.startOfDay(for: now)
        // Force-unwraps below: subtracting/adding integer days from an
        // already-normalized start-of-day cannot fail in any sane
        // calendar; if it ever did, the failure mode (crash) is far
        // better than silently producing a wrong chart.
        let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

        // Group completions by their stored date (already start-of-day,
        // courtesy of `DailyChallenge.init`'s normalization).
        var byDate: [Date: Int] = [:]
        for c in completed where c.date >= windowStart && c.date <= today {
            byDate[c.date, default: 0] += 1
        }

        // Zero-fill the entire window so the chart x-axis has no gaps
        // even when the user took several days off.
        var dailyCompletions: [DailyCount] = []
        dailyCompletions.reserveCapacity(days)
        for offset in 0..<days {
            let date = calendar.date(byAdding: .day, value: offset, to: windowStart)!
            dailyCompletions.append(DailyCount(date: date, count: byDate[date] ?? 0))
        }

        let periodCount = dailyCompletions.reduce(0) { $0 + $1.count }

        // MARK: Category breakdown

        // Fetch-once dictionary lookup; per-row category fetch would be
        // O(n*m) for trivial reason.
        let templateByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        var byCategory: [ChallengeCategory: Int] = [:]
        for c in completed {
            // A daily without a resolvable template can't be attributed
            // to a category — skip rather than miscount.
            guard let template = templateByID[c.templateId] else { continue }
            byCategory[template.category, default: 0] += 1
        }
        // Always emit all four categories — see `categoryCompletions`'s
        // doc comment for why.
        let categoryCompletions = ChallengeCategory.allCases.map {
            CategoryCount(category: $0, count: byCategory[$0] ?? 0)
        }

        return StatsData(
            totalCompleted: completed.count,
            totalSkipped: skipped.count,
            completionRate: completionRate,
            periodCount: periodCount,
            dailyCompletions: dailyCompletions,
            categoryCompletions: categoryCompletions
        )
    }
}
