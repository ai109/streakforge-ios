//
//  ChallengeDifficulty.swift
//  StreakForge
//
//  How hard a challenge is — drives XP reward and the difficulty pill.
//

import SwiftUI

/// Difficulty of a `ChallengeTemplate`.
///
/// Drives two visible behaviors:
/// * The XP awarded on completion (`baseXP`), set per the spec to
///   10 / 20 / 35.
/// * The color of the difficulty pill on challenge cards (green / amber /
///   red — matches the universally-understood difficulty ramp).
enum ChallengeDifficulty: String, Codable, CaseIterable, Identifiable, Hashable {

    case easy
    case medium
    case hard

    var id: String { rawValue }

    /// Capitalized name shown in UI.
    var displayName: String {
        switch self {
        case .easy:    "Easy"
        case .medium:  "Medium"
        case .hard:    "Hard"
        }
    }

    /// Base XP reward for completing a challenge of this difficulty.
    ///
    /// Values are exactly what the spec calls for. `ProgressService` adds
    /// the streak bonus on top of this — keeping the base reward isolated
    /// here means tuning difficulty XP later won't touch the streak code.
    var baseXP: Int {
        switch self {
        case .easy:    10
        case .medium:  20
        case .hard:    35
        }
    }

    /// Pill color for challenge cards. Reuses the semantic state colors
    /// (`success` / `warning` / `danger`) instead of inventing a parallel
    /// "difficulty palette" — green/amber/red is already a learned signal.
    var color: Color {
        switch self {
        case .easy:    AppColors.difficultyEasy
        case .medium:  AppColors.difficultyMedium
        case .hard:    AppColors.difficultyHard
        }
    }
}
