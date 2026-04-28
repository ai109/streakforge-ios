//
//  BadgeKind.swift
//  StreakForge
//
//  The single source of truth for the set of unlockable badges — their
//  identity, display metadata, and (via `BadgeEvaluator`) unlock criteria.
//

import Foundation

/// Every distinct badge the app ships.
///
/// `BadgeKind` is the authority on a badge's identity (UUID), its display
/// metadata (name / description / SF Symbol), and — implicitly via
/// `BadgeEvaluator`'s switch on this enum — its unlock criterion.
///
/// The persisted `Badge` `@Model` row stores a copy of name/description/
/// iconName so the Badges screen can render purely from `@Query` without
/// having to re-derive metadata at view time. `SeedDataService` keeps
/// those rows in sync by driving its insert loop from `BadgeKind.allCases`.
///
/// This double-bookkeeping (kind enum + persisted row) buys two things:
/// * Renaming a badge in the enum and re-running the seeder updates the
///   row content automatically (well — the seeder is currently
///   insert-only, so renames only land on fresh installs; that's the
///   right trade-off for a v1).
/// * Tests can construct `Snapshot`s and check the evaluator without
///   touching SwiftData at all, because `BadgeKind` is pure data.
enum BadgeKind: String, CaseIterable, Identifiable, Hashable {

    case firstStep
    case streak3
    case streak7
    case completed10
    case completed25
    case completed50
    case nightOwl
    case earlyBird
    case weekendWarrior
    case categorySpecialist

    /// Stable UUID — must stay byte-identical to the row inserted by the
    /// seeder. Hardcoded literals (rather than computed from the case name)
    /// because UUID stability across app versions is a hard requirement;
    /// any algorithmic derivation could shift if the algorithm ever changes.
    ///
    /// The force-unwrap on `UUID(uuidString:)` is safe because every literal
    /// is a hand-typed constant of the correct length and character set —
    /// a malformed literal would crash on the very first launch.
    var id: UUID {
        switch self {
        case .firstStep:          UUID(uuidString: "00000002-0000-4000-8000-000000000001")!
        case .streak3:            UUID(uuidString: "00000002-0000-4000-8000-000000000002")!
        case .streak7:            UUID(uuidString: "00000002-0000-4000-8000-000000000003")!
        case .completed10:        UUID(uuidString: "00000002-0000-4000-8000-000000000004")!
        case .completed25:        UUID(uuidString: "00000002-0000-4000-8000-000000000005")!
        case .completed50:        UUID(uuidString: "00000002-0000-4000-8000-000000000006")!
        case .nightOwl:           UUID(uuidString: "00000002-0000-4000-8000-000000000007")!
        case .earlyBird:          UUID(uuidString: "00000002-0000-4000-8000-000000000008")!
        case .weekendWarrior:     UUID(uuidString: "00000002-0000-4000-8000-000000000009")!
        case .categorySpecialist: UUID(uuidString: "00000002-0000-4000-8000-00000000000A")!
        }
    }

    /// Short display name shown on the badge tile.
    var displayName: String {
        switch self {
        case .firstStep:          "First Step"
        case .streak3:            "3-Day Streak"
        case .streak7:            "7-Day Streak"
        case .completed10:        "10 Completed"
        case .completed25:        "25 Completed"
        case .completed50:        "50 Completed"
        case .nightOwl:           "Night Owl"
        case .earlyBird:          "Early Bird"
        case .weekendWarrior:     "Weekend Warrior"
        case .categorySpecialist: "Category Specialist"
        }
    }

    /// One-sentence description shown in the badge detail sheet — also
    /// doubles as the unlock criterion stated in plain English (so the
    /// user knows what to do to earn it).
    var description: String {
        switch self {
        case .firstStep:          "Complete your very first challenge."
        case .streak3:            "Complete at least one challenge three days in a row."
        case .streak7:            "A whole week of consecutive completions."
        case .completed10:        "Complete a total of 10 challenges."
        case .completed25:        "Complete a total of 25 challenges."
        case .completed50:        "Complete a total of 50 challenges."
        case .nightOwl:           "Complete a challenge after 10pm."
        case .earlyBird:          "Complete a challenge before 7am."
        case .weekendWarrior:     "Complete at least one challenge on both Saturday and Sunday of the same week."
        case .categorySpecialist: "Complete 10 challenges in a single category."
        }
    }

    /// SF Symbol used on the badge tile and detail sheet.
    var iconName: String {
        switch self {
        case .firstStep:          "flag.checkered"
        case .streak3:            "flame"
        case .streak7:            "flame.fill"
        case .completed10:        "10.circle.fill"
        case .completed25:        "25.circle.fill"
        case .completed50:        "50.circle.fill"
        case .nightOwl:           "moon.stars.fill"
        case .earlyBird:          "sunrise.fill"
        case .weekendWarrior:     "calendar.badge.checkmark"
        case .categorySpecialist: "star.fill"
        }
    }
}
