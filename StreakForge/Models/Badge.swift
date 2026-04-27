//
//  Badge.swift
//  StreakForge
//
//  An achievement the user unlocks by hitting a specific milestone.
//

import Foundation
import SwiftData

/// A single unlockable badge.
///
/// All badges (locked and unlocked) live as persisted rows from first
/// launch — `SeedDataService` (Step 3) inserts the full set of 8 with
/// `unlockedAt == nil`. `BadgeService` (Step 4) re-evaluates them after
/// every completion and fills in `unlockedAt` for any that newly qualify.
///
/// Persisting locked badges (rather than deriving them at render time
/// from a list of definitions in code) means the Badges screen is just a
/// `@Query` of all `Badge` rows — no merge step, no "did the user see
/// this one already?" bookkeeping.
@Model
final class Badge {

    /// Stable identifier. Marked `.unique` so the seeder can re-run
    /// safely on every launch without producing duplicates.
    @Attribute(.unique)
    var id: UUID

    /// Short display name (e.g. "First Step", "7-Day Streak"). Used as
    /// the badge tile's primary label.
    var name: String

    /// One-sentence description of how the badge is earned. Shown in the
    /// detail sheet that opens when the user taps a badge.
    var badgeDescription: String

    /// SF Symbol name used as the badge's icon. Stored as a string (not a
    /// strongly-typed enum) because the seed list is small and we'd
    /// rather see the symbol name in the seed data than a layer of
    /// indirection through cases.
    var iconName: String

    /// When the badge was unlocked, or `nil` if it's still locked.
    /// Storing the timestamp — not a boolean — lets the UI sort
    /// unlocked badges by when they were earned and gives us a "you
    /// earned this on …" line for free in the detail sheet.
    var unlockedAt: Date?

    /// Convenience: is this badge currently unlocked?
    var isUnlocked: Bool { unlockedAt != nil }

    // MARK: Init

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.badgeDescription = description
        self.iconName = iconName
        self.unlockedAt = unlockedAt
    }
}
