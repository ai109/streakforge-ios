//
//  DailyChallenge.swift
//  StreakForge
//
//  A single challenge offered to the user on a specific day.
//

import Foundation
import SwiftData

/// One challenge for one day — the per-day instantiation of a
/// `ChallengeTemplate`.
///
/// Three of these are created at the start of each day by
/// `ChallengeService.ensureTodayExists(...)`. They start in `.pending`
/// and are mutated to `.completed` or `.skipped` by the user. The History
/// screen is essentially "all `DailyChallenge` rows where status != pending,
/// newest first".
///
/// ## Why we store `templateId` instead of a `@Relationship`
///
/// The spec calls for `templateId` explicitly. SwiftData `@Relationship`
/// would be more idiomatic (free traversal, cascade behavior, integrity
/// guarantees) but storing a UUID has two practical advantages here:
/// * Templates never change — the relationship would just be a stable
///   pointer, which a UUID models perfectly without graph overhead.
/// * If we ever migrate templates (e.g. shipping a v2 set in an update
///   while keeping old history readable), a UUID survives template
///   deletion gracefully where a relationship would null out or cascade.
///
/// The lookup ergonomics cost is small: `ChallengeService` exposes a
/// `template(for:)` helper.
@Model
final class DailyChallenge {

    /// Local identifier. Not unique-constrained — there is no business
    /// reason to reject duplicates beyond "the service shouldn't create
    /// them in the first place", and the unique index would just slow
    /// inserts down for a guarantee we already enforce in code.
    var id: UUID

    /// The day this challenge belongs to, normalized to start-of-day in
    /// the user's current calendar.
    ///
    /// Why start-of-day: we want "all challenges for today" queries to be
    /// cheap and exact (`date == startOfToday`) rather than ranged
    /// (`date >= startOfToday && date < endOfToday`). Normalizing on
    /// insert gives us that.
    var date: Date

    /// Foreign key into `ChallengeTemplate.id`. See the type-level note
    /// above for why this isn't a `@Relationship`.
    var templateId: UUID

    /// Lifecycle state. Stored as a raw `String` and surfaced via the
    /// `status` typed accessor below.
    private var statusRaw: String

    /// Wall-clock timestamp of when the user tapped "Complete". `nil`
    /// while `status == .pending` or `.skipped`. Kept as a separate
    /// field (rather than reusing `date`) because it's used by the
    /// "Night Owl" / "Early Bird" badges, which need the *time* of day.
    var completedAt: Date?

    // MARK: Typed accessor

    /// Strongly-typed view of `statusRaw`. Defaults to `.pending` on read
    /// failure — the safest fallback (the user can still act on it).
    var status: ChallengeStatus {
        get { ChallengeStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    // MARK: Init

    init(
        id: UUID = UUID(),
        date: Date,
        templateId: UUID,
        status: ChallengeStatus = .pending,
        completedAt: Date? = nil
    ) {
        self.id = id
        // Normalize on construction so callers don't have to remember to
        // pre-normalize. See `date`'s doc comment for why.
        self.date = Calendar.current.startOfDay(for: date)
        self.templateId = templateId
        self.statusRaw = status.rawValue
        self.completedAt = completedAt
    }
}
