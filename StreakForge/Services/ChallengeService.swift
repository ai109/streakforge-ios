//
//  ChallengeService.swift
//  StreakForge
//
//  Owns the daily-challenge selection algorithm and the swap operation.
//  Pure selection logic lives in `ChallengeSelector` so it can be tested
//  in isolation; the wrapper service handles SwiftData fetches and writes.
//

import Foundation
import SwiftData

// MARK: - Selector

/// Pure challenge-selection algorithm. No SwiftData; takes plain inputs
/// and returns plain outputs so unit tests can drive every branch.
enum ChallengeSelector {

    /// Picks `count` templates from `pool`, preferring those not used
    /// since `cutoff`. If the eligible subset is too small, fills the
    /// remainder from the *least-recently-used* of the rest.
    ///
    /// - Parameters:
    ///   - count: How many templates to return. Caller's responsibility to
    ///     ensure `pool.count >= count` (otherwise the result is shorter).
    ///   - pool: The full set of available templates.
    ///   - recentlyUsed: Map from template id → most recent date that
    ///     template appeared in any `DailyChallenge`. Templates absent
    ///     from the map are treated as "never used".
    ///   - cutoff: The recency boundary. Templates with a `recentlyUsed`
    ///     date strictly before `cutoff` are eligible; on or after,
    ///     they're "recent" and avoided.
    ///   - randomIndex: A deterministic seam for randomness. Defaults to
    ///     `Int.random(in: 0..<n)`. Tests inject a closure that returns
    ///     fixed indices for reproducible picks.
    static func pick(
        count: Int,
        from pool: [ChallengeTemplate],
        recentlyUsed: [UUID: Date],
        cutoff: Date,
        randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }
    ) -> [ChallengeTemplate] {

        // Partition by eligibility. We preserve the original `pool` order
        // here (rather than shuffling) because order should be controlled
        // by the random pick below — order coming in is meaningless and
        // making it meaningful would make tests fragile.
        var eligible = pool.filter { template in
            guard let lastUsed = recentlyUsed[template.id] else {
                // Never used → always eligible.
                return true
            }
            return lastUsed < cutoff
        }

        var picked: [ChallengeTemplate] = []
        picked.reserveCapacity(count)

        // Phase 1: random picks from the eligible pool. We `remove(at:)`
        // each pick so subsequent picks within the same call can't draw
        // the same template twice.
        while picked.count < count && !eligible.isEmpty {
            let idx = randomIndex(eligible.count)
            // Defensive clamp: a pathological closure could return out of
            // range. `min(max(...))` keeps us inside the valid index range
            // without crashing.
            let safeIdx = min(max(idx, 0), eligible.count - 1)
            picked.append(eligible.remove(at: safeIdx))
        }

        // Phase 2: fall back to the least-recently-used templates if we
        // couldn't satisfy `count` from the eligible set. This handles
        // the small-pool / bootstrap case (e.g. only 2 templates exist
        // but we need 3) — the spec calls for LRU fill so the user still
        // gets a full day's worth of challenges.
        if picked.count < count {
            let pickedIDs = Set(picked.map(\.id))
            // Sort by least-recently-used. `nil` (never-used) sorts as
            // `.distantPast` — which would mean "never used wins", but
            // we already exhausted those in Phase 1, so they can't be
            // here. The sort is well-defined regardless.
            let fallback = pool
                .filter { !pickedIDs.contains($0.id) }
                .sorted { (a, b) in
                    let aDate = recentlyUsed[a.id] ?? .distantPast
                    let bDate = recentlyUsed[b.id] ?? .distantPast
                    return aDate < bDate
                }
            for template in fallback {
                if picked.count >= count { break }
                picked.append(template)
            }
        }

        return picked
    }
}

// MARK: - Result types

/// Outcome of a swap attempt. The view layer in Step 6 surfaces a
/// different toast / haptic for each case, so we model the failures
/// distinctly rather than collapsing them into `nil`.
enum SwapResult: Equatable {
    /// The swap succeeded and the (mutated) challenge is returned.
    case swapped(DailyChallenge)
    /// User has already used their one swap for today.
    case budgetExhausted
    /// The challenge wasn't pending (already completed/skipped).
    case notPending
    /// No template anywhere in the catalog could be picked. Practically
    /// unreachable in the shipped app (we always have ≥30 templates) but
    /// modeled so tests can exercise the empty-pool case.
    case noEligibleTemplate

    static func == (lhs: SwapResult, rhs: SwapResult) -> Bool {
        switch (lhs, rhs) {
        case (.swapped(let a), .swapped(let b)):     a.id == b.id
        case (.budgetExhausted, .budgetExhausted):   true
        case (.notPending, .notPending):             true
        case (.noEligibleTemplate, .noEligibleTemplate): true
        default:                                     false
        }
    }
}

// MARK: - Service

/// SwiftData-backed wrapper around `ChallengeSelector`.
struct ChallengeService {

    /// Injectable clock — same purpose as on `ProgressService`.
    var now: () -> Date = { .now }

    /// How many days the recency window covers. Stored as a property so
    /// tests can shrink it (e.g. `recencyDays = 1`) without rewriting
    /// internal date math, and so a future tuning pass doesn't mean
    /// chasing the literal `7` through the code.
    var recencyDays: Int = 7

    /// Default daily challenge count. The spec set this at 3.
    var defaultDailyCount: Int = 3

    /// Random-index generator for the selector. Defaults to
    /// `Int.random(in:)`. Tests inject a deterministic closure.
    var randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }

    // MARK: ensureTodayExists

    /// Guarantees today has a full set of `DailyChallenge` rows. If today
    /// already has any, returns those untouched (partial state is treated
    /// as "we already picked"). Otherwise picks fresh challenges.
    @discardableResult
    func ensureTodayExists(in context: ModelContext, count: Int? = nil) -> [DailyChallenge] {
        let n = count ?? defaultDailyCount
        let today = Calendar.current.startOfDay(for: now())

        // Fetch all dailies and filter in Swift. We avoid `#Predicate`
        // here because `Date == Date` predicates have historically been
        // touchy in SwiftData; at our scale (30–365 rows) the in-memory
        // filter is free.
        let allDaily = (try? context.fetch(FetchDescriptor<DailyChallenge>())) ?? []
        let todays = allDaily.filter { $0.date == today }
        if !todays.isEmpty {
            return todays
        }

        let picks = pickFreshTemplates(count: n, in: context, todayDailies: allDaily)
        var inserted: [DailyChallenge] = []
        for template in picks {
            let dc = DailyChallenge(date: today, templateId: template.id)
            context.insert(dc)
            inserted.append(dc)
        }
        try? context.save()
        return inserted
    }

    // MARK: swap

    /// Replaces `challenge`'s template with a fresh pick. Enforces the
    /// 1-swap-per-day budget and the same 7-day recency rule as initial
    /// selection. Resets the daily swap counter when crossing midnight.
    func swap(_ challenge: DailyChallenge, in context: ModelContext) -> SwapResult {
        guard challenge.status == .pending else {
            return .notPending
        }

        let today = Calendar.current.startOfDay(for: now())
        let progress = ProgressService(now: now).current(in: context)

        // Roll the swap budget over if we've crossed midnight since the
        // last reset. Storing the date (not just relying on a scheduled
        // task) keeps this correct even if the app stayed closed across
        // midnight — see `UserProgress.swapsResetDate`.
        if progress.swapsResetDate != today {
            progress.swapsUsedToday = 0
            progress.swapsResetDate = today
        }

        guard progress.swapsUsedToday < 1 else {
            return .budgetExhausted
        }

        // The selector's recency map already includes today's templates
        // (today is within the cutoff window), so today's other two
        // challenges and the one we're swapping are naturally excluded.
        // No separate filter needed.
        let allDaily = (try? context.fetch(FetchDescriptor<DailyChallenge>())) ?? []
        let picks = pickFreshTemplates(count: 1, in: context, todayDailies: allDaily)

        guard let newTemplate = picks.first, newTemplate.id != challenge.templateId else {
            // Either the pool was empty (impossible in shipping) or the
            // selector somehow handed us back the same template. Treat
            // both as "couldn't swap" rather than mutating.
            return .noEligibleTemplate
        }

        // Mutate in place — preserves the row's `id` and `date`, which
        // means anything keyed off those (e.g. the Today screen's
        // animation identity) doesn't reshuffle.
        challenge.templateId = newTemplate.id
        progress.swapsUsedToday += 1

        try? context.save()
        return .swapped(challenge)
    }

    // MARK: Lookup

    /// Resolves a `DailyChallenge` to its template. Returns `nil` only if
    /// the template was deleted under our feet (shouldn't happen — seeded
    /// templates aren't removed — but worth modeling defensively).
    func template(for challenge: DailyChallenge, in context: ModelContext) -> ChallengeTemplate? {
        let id = challenge.templateId
        let templates = (try? context.fetch(FetchDescriptor<ChallengeTemplate>())) ?? []
        return templates.first { $0.id == id }
    }

    // MARK: - Internal helpers

    /// Glue between `ChallengeSelector` and SwiftData: builds the recency
    /// map from existing dailies and runs the pure selector.
    private func pickFreshTemplates(
        count: Int,
        in context: ModelContext,
        todayDailies: [DailyChallenge]
    ) -> [ChallengeTemplate] {
        let allTemplates = (try? context.fetch(FetchDescriptor<ChallengeTemplate>())) ?? []
        let recencyMap = buildRecencyMap(from: todayDailies)

        let today = Calendar.current.startOfDay(for: now())
        // Force-unwrap: subtracting an Int day count from a normalized
        // start-of-day cannot fail in any sane calendar.
        let cutoff = Calendar.current.date(byAdding: .day, value: -recencyDays, to: today)!

        return ChallengeSelector.pick(
            count: count,
            from: allTemplates,
            recentlyUsed: recencyMap,
            cutoff: cutoff,
            randomIndex: randomIndex
        )
    }

    /// Builds `templateId → mostRecentDateUsed` from a flat list of
    /// dailies. Kept as a pure helper so it can be reused (and so the
    /// service's hot path doesn't re-fetch the same data twice).
    private func buildRecencyMap(from dailies: [DailyChallenge]) -> [UUID: Date] {
        var map: [UUID: Date] = [:]
        for d in dailies {
            // Keep the latest date per template — `max` rather than
            // overwrite so we don't depend on fetch ordering.
            if let existing = map[d.templateId] {
                if d.date > existing { map[d.templateId] = d.date }
            } else {
                map[d.templateId] = d.date
            }
        }
        return map
    }
}
