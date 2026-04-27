//
//  ChallengeCategory.swift
//  StreakForge
//
//  The four buckets every challenge belongs to.
//

import SwiftUI

/// The category a `ChallengeTemplate` (and therefore a `DailyChallenge`)
/// belongs to.
///
/// Stored on `@Model` types as a raw `String` so SwiftData can persist it
/// without a custom transformer. The raw values are the lowercased English
/// names — short, stable identifiers that are safe to use as analytics
/// keys later, and human-readable when inspecting the SQLite store.
///
/// `CaseIterable` is required so `BadgeService`'s "Category Specialist"
/// evaluation and the Stats screen's per-category breakdown can iterate
/// every category without hardcoding the list.
enum ChallengeCategory: String, Codable, CaseIterable, Identifiable, Hashable {

    case study
    case social
    case health
    case mindfulness

    /// Stable identifier for `Identifiable` (used by SwiftUI `ForEach`).
    var id: String { rawValue }

    /// Capitalized name shown in UI. Kept here (not in the view layer)
    /// because every screen that mentions the category needs the same
    /// label; centralizing it avoids drift between Today and History.
    var displayName: String {
        switch self {
        case .study:        "Study"
        case .social:       "Social"
        case .health:       "Health"
        case .mindfulness:  "Mindfulness"
        }
    }

    /// SF Symbol used wherever the category is iconified — challenge cards,
    /// stats charts, history filter chips. We pick *filled* variants so the
    /// glyphs stay legible at the small sizes used in pills.
    var iconName: String {
        switch self {
        case .study:        "book.fill"
        case .social:       "bubble.left.and.bubble.right.fill"
        case .health:       "heart.fill"
        case .mindfulness:  "leaf.fill"
        }
    }

    /// The category's brand color from `AppColors`. Lives on the enum so
    /// callers can do `category.color` instead of every view wiring up its
    /// own switch — keeps the four-color mapping in exactly one place.
    var color: Color {
        switch self {
        case .study:        AppColors.categoryStudy
        case .social:       AppColors.categorySocial
        case .health:       AppColors.categoryHealth
        case .mindfulness:  AppColors.categoryMindfulness
        }
    }
}
