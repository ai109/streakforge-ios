//
//  SummaryCard.swift
//  StreakForge
//
//  One of the three at-a-glance cards across the top of the Stats screen.
//

import SwiftUI

/// A compact card showing one number with an icon and a label.
///
/// Used as a row of three at the top of the Stats screen (Completed /
/// Completion rate / Period). The visual weight is in the number, not
/// the chrome — small icon, big number, small label — because the user
/// scans these in a glance and shouldn't have to read prose to find
/// "what's my completion rate".
struct SummaryCard: View {

    let iconName: String
    let value: String
    let label: String
    /// Accent color for the icon and the number. Pass a category color or
    /// a semantic color (`AppColors.success`, `.primary`, etc.) — the
    /// background tint is derived from this at 12% opacity for a cohesive
    /// look without an extra parameter.
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .bold))
                Text(label)
                    .font(AppTypography.captionSmall)
            }
            .foregroundStyle(tint)

            Text(value)
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
                // Allow shrink-to-fit when the value is long ("100%",
                // "150 done") so the card doesn't push its neighbors off
                // the row at smaller text sizes.
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            // The 12%-tinted fill ties the card to its accent without
            // dominating; the background also doubles as the touch
            // target if we ever add tap-to-drilldown.
            tint.opacity(0.10),
            in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(tint.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    HStack(spacing: AppSpacing.sm) {
        SummaryCard(iconName: "checkmark.seal.fill", value: "32", label: "Completed", tint: AppColors.primary)
        SummaryCard(iconName: "percent",            value: "82%", label: "Completion", tint: AppColors.success)
        SummaryCard(iconName: "calendar",           value: "12", label: "This week",  tint: AppColors.accent)
    }
    .padding()
    .background(AppColors.background)
}
