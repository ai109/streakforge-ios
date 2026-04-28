//
//  ChallengeSelectorTests.swift
//  StreakForgeTests
//
//  Pure unit tests for `ChallengeSelector.pick(...)`.
//

import Testing
import Foundation
@testable import StreakForge

/// Tests for the daily-challenge selection algorithm.
///
/// Every test injects a deterministic `randomIndex` closure (always
/// returning 0) so picks are reproducible. The combination of
/// `randomIndex == 0` plus the algorithm's "remove on pick" semantics
/// means picks happen in pool order — easy to assert against.
@Suite("ChallengeSelector")
struct ChallengeSelectorTests {

    /// Builds a fresh test template with a unique UUID each call.
    private func makeTemplate(_ category: ChallengeCategory = .study) -> ChallengeTemplate {
        ChallengeTemplate(
            title: "Test challenge",
            description: "Test description",
            category: category,
            difficulty: .easy,
            estMinutes: 10
        )
    }

    /// Stub randomIndex — always picks index 0.
    private let alwaysFirst: (Int) -> Int = { _ in 0 }

    @Test("Picks `count` from pool when nothing is recent")
    func picksFromEmptyRecency() {
        let pool = (0..<5).map { _ in makeTemplate() }
        let result = ChallengeSelector.pick(
            count: 3,
            from: pool,
            recentlyUsed: [:],
            cutoff: .now,
            randomIndex: alwaysFirst
        )
        #expect(result.count == 3)
        // With randomIndex == 0 and remove-on-pick, picks are pool[0..2].
        #expect(result.map(\.id) == pool.prefix(3).map(\.id))
    }

    @Test("Templates used since cutoff are excluded from eligible pool")
    func excludesRecentlyUsed() {
        let pool = (0..<5).map { _ in makeTemplate() }
        // Cutoff = 7 days ago. Mark pool[0..1] as used yesterday — both
        // are within the recency window and should be excluded.
        let cutoff = Date(timeIntervalSinceNow: -7 * 86400)
        let recently: [UUID: Date] = [
            pool[0].id: Date(timeIntervalSinceNow: -1 * 86400),
            pool[1].id: Date(timeIntervalSinceNow: -1 * 86400),
        ]
        let result = ChallengeSelector.pick(
            count: 3,
            from: pool,
            recentlyUsed: recently,
            cutoff: cutoff,
            randomIndex: alwaysFirst
        )
        #expect(result.count == 3)
        let resultIDs = Set(result.map(\.id))
        let allowedIDs = Set(pool[2...].map(\.id))
        // Result must be exactly the eligible (non-recent) templates.
        #expect(resultIDs == allowedIDs)
    }

    @Test("Falls back to least-recently-used when eligible pool is too small")
    func fallsBackToLRU() {
        let pool = (0..<5).map { _ in makeTemplate() }
        let cutoff = Date(timeIntervalSinceNow: -7 * 86400)
        // Mark pool[0..2] as used recently — pool[0] longest ago,
        // pool[2] most recent. Only pool[3..4] are eligible.
        let recently: [UUID: Date] = [
            pool[0].id: Date(timeIntervalSinceNow: -3 * 86400),  // oldest in recent set
            pool[1].id: Date(timeIntervalSinceNow: -2 * 86400),
            pool[2].id: Date(timeIntervalSinceNow: -1 * 86400),  // newest in recent set
        ]
        let result = ChallengeSelector.pick(
            count: 3,
            from: pool,
            recentlyUsed: recently,
            cutoff: cutoff,
            randomIndex: alwaysFirst
        )
        #expect(result.count == 3)

        // Phase 1 should consume both eligible templates.
        #expect(result.contains { $0.id == pool[3].id })
        #expect(result.contains { $0.id == pool[4].id })

        // Phase 2 fallback should pick the *oldest* recent template
        // (least-recently-used). pool[0] was used 3 days ago — the
        // oldest of the three recent ones — so it should be the
        // fallback pick.
        #expect(result.contains { $0.id == pool[0].id })

        // The most-recently-used template (pool[2]) should NOT be
        // picked — we'd rather repeat something the user hasn't seen
        // in days than show them yesterday's challenge again.
        #expect(!result.contains { $0.id == pool[2].id })
    }

    @Test("Returned array is shorter than count when pool is small enough")
    func smallerPoolThanCount() {
        let pool = (0..<2).map { _ in makeTemplate() }
        let result = ChallengeSelector.pick(
            count: 5,
            from: pool,
            recentlyUsed: [:],
            cutoff: .now,
            randomIndex: alwaysFirst
        )
        // We can only ever return as many templates as exist.
        #expect(result.count == 2)
    }

    @Test("No duplicates within a single pick batch")
    func noDuplicatesWithinPick() {
        let pool = (0..<3).map { _ in makeTemplate() }
        let result = ChallengeSelector.pick(
            count: 3,
            from: pool,
            recentlyUsed: [:],
            cutoff: .now,
            randomIndex: alwaysFirst
        )
        let ids = result.map(\.id)
        // Set count must equal array count → no duplicates.
        #expect(Set(ids).count == ids.count)
    }

    @Test("Out-of-range randomIndex is clamped, not crash")
    func defensiveClampOnBadRandomIndex() {
        let pool = (0..<3).map { _ in makeTemplate() }
        // Pathological closure — always returns index 999, way out of
        // range. The selector's `min(max(...))` clamp should keep us
        // inside the array bounds rather than crashing.
        let result = ChallengeSelector.pick(
            count: 3,
            from: pool,
            recentlyUsed: [:],
            cutoff: .now,
            randomIndex: { _ in 999 }
        )
        #expect(result.count == 3)
    }
}
