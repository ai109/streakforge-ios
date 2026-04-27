//
//  AppTypography.swift
//  StreakForge
//
//  Centralized font scale. Built on top of SwiftUI's Dynamic Type so all
//  sizes scale with the user's accessibility text settings.
//

import SwiftUI

/// Namespace for every font style used by StreakForge.
///
/// All styles are derived from system text styles (via `.system(.titleX)`)
/// rather than fixed point sizes, which gives us free Dynamic Type support
/// — the user's accessibility text size is honored automatically and we
/// don't need to maintain a parallel "large text" theme.
///
/// Two design choices:
/// * Display + Title use `.rounded` — friendlier than the default SF and
///   matches the playful "habit-tracker" tone (think Duolingo / Strava
///   numerals). Body copy stays default SF for legibility.
/// * Numeric styles use `.monospacedDigit()` so XP / streak numbers
///   don't jitter when their digits change (e.g. 99 → 100).
enum AppTypography {

    // MARK: Display — for hero numbers (XP total, current streak)

    /// Largest display style. Used by the XP counter on the Today/Stats
    /// hero, and the unlocked-badge celebration sheet.
    static let displayLarge = Font.system(.largeTitle, design: .rounded, weight: .heavy)
        .monospacedDigit() // hero numbers change frequently — keep them width-stable

    /// Mid display style — secondary hero figures (best streak, today's XP).
    static let displayMedium = Font.system(.title, design: .rounded, weight: .bold)
        .monospacedDigit()

    // MARK: Titles — section headers & card titles

    /// Tab/screen titles — appears in nav bars and as screen-level h1s.
    static let titleLarge = Font.system(.title2, design: .rounded, weight: .bold)

    /// Card titles, section headings within a screen.
    static let titleMedium = Font.system(.title3, design: .rounded, weight: .semibold)

    /// Subsection / list-row primary text.
    static let titleSmall = Font.system(.headline, design: .rounded, weight: .semibold)

    // MARK: Body — primary readable text

    /// Default body copy — challenge descriptions, settings rows.
    static let body = Font.system(.body, design: .default, weight: .regular)

    /// Emphasized body — drawing attention without bumping to a title.
    static let bodyEmphasized = Font.system(.body, design: .default, weight: .semibold)

    /// Slightly smaller body — used by callouts under inputs and badge
    /// descriptions where space is tight.
    static let callout = Font.system(.callout, design: .default, weight: .regular)

    // MARK: Caption — metadata, pills, hints

    /// Standard caption — "12 min", "Easy", "2 days ago".
    static let caption = Font.system(.caption, design: .default, weight: .medium)

    /// Smallest caption — used for tiny badges (e.g. "+15 XP") where
    /// even regular caption would feel heavy.
    static let captionSmall = Font.system(.caption2, design: .default, weight: .semibold)

    // MARK: Numeric

    /// Inline numeric style — XP pills, completion counts. Same family as
    /// `bodyEmphasized` but with monospaced digits to prevent layout jitter
    /// during the count-up animation on completion.
    static let numericInline = Font.system(.body, design: .rounded, weight: .bold)
        .monospacedDigit()

    /// Tabular numeric style — used inside the Stats screen's chart axes
    /// and weekly breakdown rows so columns line up.
    static let numericTabular = Font.system(.caption, design: .rounded, weight: .semibold)
        .monospacedDigit()
}
