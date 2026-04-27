//
//  AppColors.swift
//  StreakForge
//
//  Central palette for the app. Defined entirely in code (not in the asset
//  catalog) so the values live in source review and can be diffed.
//

import SwiftUI

/// Namespace for every color used by StreakForge.
///
/// Naming follows a *role-based* convention (`primary`, `surface`,
/// `textSecondary`, …) rather than a *value-based* one (`orange500`,
/// `navy900`, …) so that swapping the palette later only touches this file.
///
/// The palette deliberately leans warm — orange/amber primary on a near-black
/// dark background, off-white in light mode — to evoke the "forge" half of
/// the brand. Per-category colors (Study/Social/Health/Mindfulness) are kept
/// distinct enough to read at a glance even in small badges.
enum AppColors {

    // MARK: Brand

    /// Primary brand orange — used for CTAs, the active tab tint, streak
    /// highlights, and the flame icon. Slightly muted in dark mode so it
    /// doesn't vibrate against the near-black background.
    static let primary = Color(lightHex: 0xFF6B35, darkHex: 0xFF8552)

    /// Pressed/hover variant of `primary` for interactive feedback.
    static let primaryPressed = Color(lightHex: 0xE85826, darkHex: 0xE6713D)

    /// A warmer accent used sparingly — XP-gain glow, badge unlock burst.
    static let accent = Color(lightHex: 0xFFB347, darkHex: 0xFFC270)

    // MARK: Surfaces

    /// The base canvas behind every screen.
    static let background = Color(lightHex: 0xFAFAFB, darkHex: 0x0E1116)

    /// The default card / list-row surface, one elevation step above
    /// `background`. In dark mode we lift slightly toward `#1A1F2A` rather
    /// than going pure black-on-black, which would collapse depth cues.
    static let surface = Color(lightHex: 0xFFFFFF, darkHex: 0x1A1F2A)

    /// A second elevation step — used for floating sheets, popovers,
    /// and emphasized cards (e.g. today's hero challenge).
    static let surfaceElevated = Color(lightHex: 0xFFFFFF, darkHex: 0x232938)

    /// Hairline divider; intentionally low-contrast so dense lists don't
    /// turn into a grid of black lines.
    static let divider = Color(lightHex: 0xE5E7EB, darkHex: 0x2D3445)

    // MARK: Text

    /// Highest-contrast text — headlines, primary body copy.
    static let textPrimary = Color(lightHex: 0x111827, darkHex: 0xF4F5F7)

    /// Supporting text — descriptions, secondary metadata.
    static let textSecondary = Color(lightHex: 0x4B5563, darkHex: 0xB6BCCB)

    /// Lowest-contrast text — captions, hint text, "estimated time" pills.
    /// Still has to clear WCAG AA on its surface, so don't push it lighter.
    static let textMuted = Color(lightHex: 0x6B7280, darkHex: 0x8A92A6)

    // MARK: Semantic state

    /// Success/completed state. Slightly desaturated from the default
    /// system green so it sits well next to the orange brand.
    static let success = Color(lightHex: 0x10B981, darkHex: 0x34D399)

    /// Warning / "skipped" indicator.
    static let warning = Color(lightHex: 0xF59E0B, darkHex: 0xFBBF24)

    /// Destructive / danger — used by Reset Progress and confirmation dialogs.
    static let danger = Color(lightHex: 0xEF4444, darkHex: 0xF87171)

    // MARK: Categories
    //
    // Each challenge category gets its own hue. We chose colors that are
    // distinct under deuteranopia (the most common color-vision deficiency)
    // by leaning on hue *and* brightness differences — green (Health) and
    // pink (Social) for example are far apart on both axes, not just on hue.

    /// Study — indigo. Cool, focused, "academic" feel.
    static let categoryStudy = Color(lightHex: 0x6366F1, darkHex: 0x818CF8)

    /// Social — rose. Warm, human, conversational.
    static let categorySocial = Color(lightHex: 0xEC4899, darkHex: 0xF472B6)

    /// Health — green. Aligns with system "active calories" green users
    /// already associate with body/movement.
    static let categoryHealth = Color(lightHex: 0x10B981, darkHex: 0x34D399)

    /// Mindfulness — teal/cyan. Calmer than the other three.
    static let categoryMindfulness = Color(lightHex: 0x06B6D4, darkHex: 0x22D3EE)

    // MARK: Difficulty
    //
    // Same hues as the semantic-state colors — green/amber/red is a
    // universally legible difficulty ramp, no need to invent a separate one.

    /// Easy — green.
    static let difficultyEasy = success

    /// Medium — amber.
    static let difficultyMedium = warning

    /// Hard — red.
    static let difficultyHard = danger

    // MARK: Gradients

    /// The flame gradient used on the streak indicator and key hero
    /// elements. Goes from accent amber to primary orange so it reads as
    /// "hot at the bottom, brighter on top" — like an actual flame.
    static let flameGradient = LinearGradient(
        colors: [accent, primary, primaryPressed],
        startPoint: .top,
        endPoint: .bottom
    )
}
