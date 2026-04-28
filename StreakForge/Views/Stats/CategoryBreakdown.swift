//
//  CategoryBreakdown.swift
//  StreakForge
//
//  Per-category horizontal bars showing relative completion counts.
//

import SwiftUI

/// Vertical stack of one bar per category.
///
/// We *don't* use Apple Charts here even though we could. A custom row
/// layout lets each bar use its own category color (icon + bar fill +
/// label all matching), which reinforces the color-coded category
/// language used elsewhere in the app. A `Chart` would either force a
/// single style across all bars or require per-mark `foregroundStyle`s
/// keyed by category — more friction for less reward at this size.
struct CategoryBreakdown: View {

    let rows: [StatsData.CategoryCount]

    /// The denominator for the relative bar width — the largest count in
    /// the set. Computed once and shared across rows so all bars are
    /// scaled to the same maximum.
    private var maxCount: Int {
        // `max(1, …)` floors the denominator at 1 so an all-zero
        // breakdown (no completions yet) doesn't divide by zero. Bars
        // will all render at zero width, which is the correct visual.
        max(1, rows.map(\.count).max() ?? 0)
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(rows) { row in
                CategoryBreakdownRow(
                    category: row.category,
                    count: row.count,
                    fraction: Double(row.count) / Double(maxCount)
                )
            }
        }
    }
}

/// A single row in the breakdown — icon + name + bar + count.
private struct CategoryBreakdownRow: View {
    let category: ChallengeCategory
    let count: Int
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Label(category.displayName, systemImage: category.iconName)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundStyle(category.color)
                    .labelStyle(.titleAndIcon)

                Spacer(minLength: 0)

                Text("\(count)")
                    .font(AppTypography.numericInline)
                    .foregroundStyle(AppColors.textPrimary)
            }

            // Bar layer: faded track in the background, solid fill on top.
            // GeometryReader gives us the row's width to scale the fill
            // against — the alternative (using `frame(width:)` with a
            // fixed dimension) would break across device sizes.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(category.color.opacity(0.14))
                    Capsule()
                        .fill(category.color)
                        // `max(0, fraction)` guards against a future
                        // negative input (shouldn't happen — count is
                        // Int — but the floor is free insurance).
                        .frame(width: proxy.size.width * max(0, fraction))
                }
            }
            // Fixed bar height so the GeometryReader doesn't expand to
            // fill the parent — 10pt reads as a "progress bar" rather
            // than a "block".
            .frame(height: 10)
        }
    }
}

#Preview {
    let rows = [
        StatsData.CategoryCount(category: .study,        count: 12),
        StatsData.CategoryCount(category: .social,       count: 4),
        StatsData.CategoryCount(category: .health,       count: 9),
        StatsData.CategoryCount(category: .mindfulness,  count: 0),
    ]
    return CategoryBreakdown(rows: rows)
        .padding()
        .background(AppColors.background)
}
