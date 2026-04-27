//
//  ChallengeTemplate.swift
//  StreakForge
//
//  The blueprint for a challenge. Templates are seeded on first launch
//  and never mutated; each day picks 3 of them to materialize as
//  `DailyChallenge` rows.
//

import Foundation
import SwiftData

/// A reusable challenge definition.
///
/// Templates are *static content* — they describe what a challenge is
/// (title, description, category, difficulty, time estimate) without any
/// notion of when or whether it's been done. The dynamic per-day state
/// lives on `DailyChallenge`, which references this template by `id`.
///
/// We keep templates and daily instances as separate types so the seed
/// data is small (30 rows, fixed) while the daily history can grow
/// unbounded without duplicating descriptive text on every row.
@Model
final class ChallengeTemplate {

    /// Stable identifier. Marked `.unique` so the seeder can use
    /// "insert if not present" semantics on every launch without creating
    /// duplicates — `SeedDataService` (Step 3) relies on this guarantee.
    @Attribute(.unique)
    var id: UUID

    /// Short, action-oriented title (e.g. "Read 5 pages of a book").
    /// Kept under ~50 chars so it doesn't wrap on the Today card.
    var title: String

    /// One- or two-sentence description shown under the title. Used for
    /// context — what counts as "done", roughly how to do it.
    var challengeDescription: String

    /// Which of the four buckets this challenge belongs to.
    ///
    /// Stored via the underlying raw `String` so SwiftData persists it
    /// without a custom transformer. We expose a typed accessor (below)
    /// so the rest of the app deals in the enum, not strings.
    private var categoryRaw: String

    /// Difficulty — drives XP reward and the difficulty pill color.
    private var difficultyRaw: String

    /// Estimated minutes to complete. Drives the "12 min" pill on the
    /// challenge card. Kept as `Int` (not `Measurement<UnitDuration>`)
    /// because every value is a whole number of minutes and the simpler
    /// type means simpler SwiftData storage and simpler test data.
    var estMinutes: Int

    // MARK: Typed accessors for the enum-backed columns

    /// Strongly-typed view of `categoryRaw`. Falls back to `.study` if the
    /// stored string is somehow unreadable — should never happen in
    /// practice (we control all writers), but defaulting beats crashing.
    var category: ChallengeCategory {
        get { ChallengeCategory(rawValue: categoryRaw) ?? .study }
        set { categoryRaw = newValue.rawValue }
    }

    /// Strongly-typed view of `difficultyRaw`. Same fallback rationale.
    var difficulty: ChallengeDifficulty {
        get { ChallengeDifficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue }
    }

    // MARK: Init

    /// Designated initializer.
    ///
    /// `id` defaults to a fresh UUID so seed data and tests don't have to
    /// construct one explicitly; passing one in is supported when fixed
    /// IDs matter (e.g. deterministic test fixtures).
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: ChallengeCategory,
        difficulty: ChallengeDifficulty,
        estMinutes: Int
    ) {
        self.id = id
        self.title = title
        self.challengeDescription = description
        self.categoryRaw = category.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.estMinutes = estMinutes
    }
}
