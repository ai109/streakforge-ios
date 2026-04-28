//
//  BadgesHeader.swift
//  StreakForge
//
//  Top-of-screen card showing unlock progress on the Badges tab.
//

import SwiftUI

/// "X of N unlocked" header with a progress bar.
///
/// Sits above the grid so the user gets immediate quantitative feedback
/// — without it, a screen full of mostly-locked tiles would feel
/// discouraging on day one. The percentage doubles as a goal: even a
/// tiny step (1 of 10 = 10%) reads as visible progress.
struct BadgesHeader: View {

    let unlockedCount: Int
    let totalCount: Int

    /// Fraction in [0, 1]. Floors to 0 when there are no badges (which
    /// shouldn't happen — the seeder inserts 10 — but keeps the view
    /// well-defined regardless).
    private var fraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    // Two text spans so the count reads as the primary
                    // info, "of N unlocked" as the supporting context.
                    HStack(spacing: AppSpacing.xs) {
                        Text("\(unlockedCount)")
                            .font(AppTypography.displayMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("of \(totalCount) unlocked")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } icon: {
                    Image(systemName: "rosette")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }

                Spacer()

                Text("\(Int((fraction * 100).rounded()))%")
                    .font(AppTypography.numericInline)
                    .foregroundStyle(AppColors.success)
                    .monospacedDigit() // already monospaced from the font, but explicit for safety
            }

            ProgressView(value: fraction)
                .tint(AppColors.success)
                // Custom height via scaleEffect — ProgressView's intrinsic
                // height is too thin for a header element. 1.4× makes
                // it match the visual weight of the count above it.
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
                // Animate fraction changes so the bar slides smoothly
                // when a fresh unlock lands while the screen is open.
                .animation(.smooth, value: fraction)
        }
        .padding(AppSpacing.lg)
        .background(
            AppColors.surface,
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .appShadow(.card)
    }
}

#Preview("Few unlocked") {
    BadgesHeader(unlockedCount: 3, totalCount: 10)
        .padding()
        .background(AppColors.background)
}

#Preview("Most unlocked") {
    BadgesHeader(unlockedCount: 9, totalCount: 10)
        .padding()
        .background(AppColors.background)
}
