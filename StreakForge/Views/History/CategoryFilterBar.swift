//
//  CategoryFilterBar.swift
//  StreakForge
//
//  Horizontal chip bar that lets the user filter History by category.
//

import SwiftUI

/// Horizontal-scrolling chip bar for category filtering.
///
/// Built with chips (instead of a `Picker(.segmented)`) because:
/// * The category list is fixed at five entries (`All` + 4 categories),
///   each visually identifiable by color and icon — chips honor that
///   color language; segments can't.
/// * Tapping a selected chip a second time clears the filter ("toggle"
///   semantics), which segmented controls don't support natively.
struct CategoryFilterBar: View {

    /// `nil` = "All". Bound to the parent's filter state so changing the
    /// chip selection updates the filtered list immediately.
    @Binding var selection: ChallengeCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                FilterChip(
                    label: "All",
                    iconName: "square.grid.2x2",
                    color: AppColors.primary,
                    isSelected: selection == nil
                ) {
                    selection = nil
                }

                ForEach(ChallengeCategory.allCases) { category in
                    FilterChip(
                        label: category.displayName,
                        iconName: category.iconName,
                        color: category.color,
                        isSelected: selection == category
                    ) {
                        // Toggle: tapping the active chip clears it back
                        // to "All", which feels more discoverable than
                        // forcing the user to find an "X" or scroll back
                        // to the All chip.
                        selection = (selection == category) ? nil : category
                    }
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.xs)
        }
    }
}

/// One chip in the bar. Filled when selected, tinted-bordered when not.
private struct FilterChip: View {
    let label: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(AppTypography.caption)
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 8)
            .background(
                // Selected: solid color fill (high contrast — clearly
                // the active filter). Unselected: 12% tint of the same
                // color so the chip still reads as "category-tinted"
                // without competing with the selected one.
                Capsule().fill(isSelected ? color : color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        // Animate selection changes so the chip morph reads as a state
        // change rather than a snap.
        .animation(.smooth(duration: 0.18), value: isSelected)
    }
}

#Preview("All") {
    CategoryFilterBar(selection: .constant(nil))
        .background(AppColors.background)
}

#Preview("Health selected") {
    CategoryFilterBar(selection: .constant(.health))
        .background(AppColors.background)
}
