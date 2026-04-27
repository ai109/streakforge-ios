//
//  Color+Dynamic.swift
//  StreakForge
//
//  Helpers for declaring colors that adapt automatically to light/dark mode
//  without having to round-trip through the asset catalog.
//

import SwiftUI
import UIKit

// We resolve colors through `UIColor`'s trait-based dynamic provider rather
// than the asset catalog because the design palette lives in code (single
// source of truth, easy to diff in PRs, and the professor can read the exact
// values directly in source). The asset catalog stays reserved for AppIcon
// and AccentColor only.

extension Color {

    /// Builds a SwiftUI `Color` whose value depends on the current
    /// `UITraitCollection`'s `userInterfaceStyle`.
    ///
    /// - Parameters:
    ///   - light: Color used when the system is in light mode (or unspecified).
    ///   - dark:  Color used when the system is in dark mode.
    init(light: Color, dark: Color) {
        // Capture the bridged UIColor instances once so the dynamic provider
        // closure stays cheap — it can fire on every trait change.
        let lightUI = UIColor(light)
        let darkUI = UIColor(dark)
        self = Color(uiColor: UIColor { trait in
            // `.dark` is the only style we treat specially; `.unspecified`
            // and `.light` both map to the light variant, matching how
            // SwiftUI's own semantic colors behave.
            trait.userInterfaceStyle == .dark ? darkUI : lightUI
        })
    }

    /// Convenience for declaring a color from a 24-bit hex literal
    /// (e.g. `0xFF6B35`). Alpha defaults to fully opaque because every
    /// brand color in the palette is opaque; semi-transparent variants
    /// are produced via `.opacity(_:)` at the call site for clarity.
    init(hex: UInt32, opacity: Double = 1.0) {
        // Bit-shifts are used here (rather than CGFloat math on each channel)
        // because they make the byte boundaries unambiguous when reading the
        // literal — `0xFF6B35` is obviously R=FF G=6B B=35.
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// Light/dark variant from two hex literals — the most common shape
    /// in `AppColors`, hence the dedicated initializer.
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(light: Color(hex: lightHex), dark: Color(hex: darkHex))
    }
}
