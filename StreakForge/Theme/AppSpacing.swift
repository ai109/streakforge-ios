//
//  AppSpacing.swift
//  StreakForge
//
//  Spacing, corner-radius, and elevation tokens.
//

import SwiftUI

/// Geometric spacing scale used everywhere padding/spacing is applied.
///
/// We use a *named* scale (`xs`, `sm`, `md`, …) rather than scattering raw
/// numbers across views because the alternative — `.padding(13)` here,
/// `.padding(14)` there — is exactly how design systems get inconsistent.
/// If a layout truly needs a value outside the scale, the scale is wrong;
/// extend it here rather than hardcoding at the call site.
///
/// The scale is a roughly-doubling progression (4-8-12-16-24-32-48). 12
/// and 20 are included because card-internal padding lands between `sm`
/// and `md`/`lg` more often than the strict 4-8-16-32 ramp predicts.
enum AppSpacing {

    /// 2 pt — pixel-level adjustments only (icon nudges, separator insets).
    static let xxs: CGFloat = 2

    /// 4 pt — gaps between tight clusters (icon + label inside a pill).
    static let xs: CGFloat = 4

    /// 8 pt — default in-row spacing (between adjacent buttons or chips).
    static let sm: CGFloat = 8

    /// 12 pt — common interior padding for compact cards / pills.
    static let md: CGFloat = 12

    /// 16 pt — *the* default. Use unless you have a reason not to.
    static let base: CGFloat = 16

    /// 20 pt — generous interior padding for hero cards.
    static let lg: CGFloat = 20

    /// 24 pt — section gaps within a screen.
    static let xl: CGFloat = 24

    /// 32 pt — between major sections / between hero and content.
    static let xxl: CGFloat = 32

    /// 48 pt — page top/bottom margins on hero screens (e.g. Today header).
    static let xxxl: CGFloat = 48
}

/// Corner radius tokens. Kept separate from spacing because their meaning
/// is different — a 16pt gap and a 16pt corner are unrelated quantities.
enum AppRadius {

    /// 6 pt — chips, small pills.
    static let small: CGFloat = 6

    /// 12 pt — standard card corners.
    static let medium: CGFloat = 12

    /// 16 pt — emphasized cards (today's hero, badge tiles).
    static let large: CGFloat = 16

    /// 24 pt — sheets and modals.
    static let xlarge: CGFloat = 24

    /// Fully rounded — for circular avatars, FAB-style buttons.
    /// Realized as a very large radius so callers can apply it uniformly
    /// via `.clipShape(.rect(cornerRadius:))` without branching.
    static let pill: CGFloat = 999
}

/// Reusable shadow presets. Defined here so the visual depth language stays
/// consistent — every elevated card uses the same shadow, not a one-off.
struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// Subtle resting shadow under cards.
    static let card = AppShadow(
        color: .black.opacity(0.06),
        radius: 8,
        x: 0,
        y: 2
    )

    /// More pronounced — for floating sheets and the badge unlock card.
    static let elevated = AppShadow(
        color: .black.opacity(0.12),
        radius: 18,
        x: 0,
        y: 6
    )
}

extension View {
    /// Applies one of the standard `AppShadow` presets. Wrapped as a
    /// modifier so views read `.appShadow(.card)` instead of having to
    /// destructure the four parameters at every call site.
    func appShadow(_ preset: AppShadow) -> some View {
        shadow(color: preset.color, radius: preset.radius, x: preset.x, y: preset.y)
    }
}
