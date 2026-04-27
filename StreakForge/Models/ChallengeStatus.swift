//
//  ChallengeStatus.swift
//  StreakForge
//
//  The lifecycle state of a `DailyChallenge` row.
//

import SwiftUI

/// Where a `DailyChallenge` is in its lifecycle for the day.
///
/// Persisted as a raw `String` so SwiftData stores it without a transformer.
/// The three states form a small state machine:
///
/// ```
/// pending ──complete──▶ completed
///    │
///    └──skip──▶ skipped
/// ```
///
/// Once a challenge leaves `.pending`, it is terminal — completed and
/// skipped challenges are not re-openable. Swap is a separate operation
/// that *replaces* the pending row entirely rather than mutating it.
enum ChallengeStatus: String, Codable, CaseIterable, Identifiable, Hashable {

    case pending
    case completed
    case skipped

    var id: String { rawValue }

    /// Capitalized name shown in UI (e.g. History filter chips).
    var displayName: String {
        switch self {
        case .pending:    "Pending"
        case .completed:  "Completed"
        case .skipped:    "Skipped"
        }
    }

    /// SF Symbol shown next to the status label in History rows.
    /// `circle` for pending intentionally matches the empty bullet style
    /// used by Reminders/Notes — a familiar "not yet" signal.
    var iconName: String {
        switch self {
        case .pending:    "circle"
        case .completed:  "checkmark.circle.fill"
        case .skipped:    "xmark.circle.fill"
        }
    }

    /// Tint for the status pill / icon. We reuse the semantic state colors:
    /// success for completed, warning for skipped, muted for pending.
    /// (Skipped is *not* an error — it's a legitimate user choice — so it
    /// gets warning amber rather than danger red.)
    var color: Color {
        switch self {
        case .pending:    AppColors.textMuted
        case .completed:  AppColors.success
        case .skipped:    AppColors.warning
        }
    }
}
