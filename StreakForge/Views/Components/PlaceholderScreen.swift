//
//  PlaceholderScreen.swift
//  StreakForge
//
//  A themed empty-state used by the tab placeholders during early
//  development steps. Same component is reused later as the *real*
//  empty state for tabs that need one (e.g. History with no entries).
//

import SwiftUI

/// A centered, themed "nothing here yet" view.
///
/// Built as one component (rather than five separate inline placeholders)
/// because we want every tab to feel polished from Step 5 onward — using
/// raw `Text("Coming soon")` would make the app look unfinished even
/// though the navigation skeleton is intentional.
///
/// The same component will earn its keep again in Steps 6–10 when each
/// tab needs a real empty state ("No history yet", "No badges unlocked"),
/// just with a different `subtitle` and `stepHint = nil`.
struct PlaceholderScreen: View {

    /// Headline shown under the icon.
    let title: String

    /// SF Symbol displayed inside the round icon container.
    let iconName: String

    /// One-line description of what this screen will eventually show.
    let subtitle: String

    /// Development-stage hint (e.g. "Coming in Step 6"). Pass `nil` once
    /// the screen is real so the hint disappears without removing the
    /// rest of the placeholder body.
    let stepHint: String?

    var body: some View {
        ZStack {
            // Full-bleed brand background so each tab feels continuous
            // with the rest of the app, not framed inside a system gray.
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                // Round icon disc — matches the visual language of the
                // hero element on the eventual Today screen, so the
                // placeholder telegraphs the look-and-feel to come.
                ZStack {
                    Circle()
                        .fill(AppColors.surfaceElevated)
                        .frame(width: 96, height: 96)
                        .appShadow(.card)

                    Image(systemName: iconName)
                        .font(.system(size: 40, weight: .semibold))
                        // Brand orange against the off-white surface gives
                        // a single, recognizable focal point per screen.
                        .foregroundStyle(AppColors.primary)
                }

                VStack(spacing: AppSpacing.sm) {
                    Text(title)
                        .font(AppTypography.titleLarge)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }

                if let stepHint {
                    Text(stepHint)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textMuted)
                        // Pill background hints that the label is
                        // metadata, not part of the screen's content —
                        // helps the user/professor mentally discount it.
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            Capsule().fill(AppColors.surface)
                        )
                        .padding(.top, AppSpacing.sm)
                }
            }
            .padding(AppSpacing.xl)
        }
    }
}

#Preview("Light") {
    PlaceholderScreen(
        title: "Today",
        iconName: "sun.max.fill",
        subtitle: "Your three challenges for today.",
        stepHint: "Coming in Step 6"
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    PlaceholderScreen(
        title: "Stats",
        iconName: "chart.bar.xaxis",
        subtitle: "Weekly and monthly completion charts.",
        stepHint: "Coming in Step 7"
    )
    .preferredColorScheme(.dark)
}
