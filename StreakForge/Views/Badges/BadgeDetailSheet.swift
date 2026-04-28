//
//  BadgeDetailSheet.swift
//  StreakForge
//
//  Tap-to-detail sheet for a single badge.
//

import SwiftUI

/// Sheet shown when the user taps a badge in the grid.
///
/// Same layout for locked and unlocked, with two contextual differences:
/// * Unlocked badges show an "Unlocked" stamp under the icon and an
///   "Earned on …" line under the description.
/// * Locked badges show a "Locked" stamp and read the description as
///   coaching ("here's how you'll earn this").
///
/// Presented at the medium detent — a full-screen modal is overkill for
/// what's essentially three lines of text.
struct BadgeDetailSheet: View {

    let badge: Badge
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            heroIcon
            titleAndStatus
            description

            if let date = badge.unlockedAt {
                earnedLine(date)
            }

            Spacer(minLength: 0)

            doneButton
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        // Medium detent feels right for a single-screen detail; large
        // would leave too much empty space at the bottom.
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: Subviews

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    badge.isUnlocked
                        ? AnyShapeStyle(AppColors.flameGradient)
                        : AnyShapeStyle(Color.gray.opacity(0.25))
                )
                .frame(width: 128, height: 128)
                .appShadow(.elevated)

            Image(systemName: badge.iconName)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(badge.isUnlocked ? .white : Color.gray.opacity(0.55))
                // Bounce on appear — keys on a `true` value that's stable
                // for the lifetime of the sheet, which makes the symbol
                // effect fire exactly once when the sheet opens.
                .symbolEffect(.bounce, value: true)
        }
        .overlay(alignment: .bottom) {
            statusStamp
                .offset(y: 12)
        }
    }

    private var statusStamp: some View {
        Text(badge.isUnlocked ? "UNLOCKED" : "LOCKED")
            .font(AppTypography.captionSmall)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(badge.isUnlocked ? AppColors.success : AppColors.textSecondary)
            )
    }

    private var titleAndStatus: some View {
        Text(badge.name)
            .font(AppTypography.titleLarge)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.center)
    }

    private var description: some View {
        Text(badge.badgeDescription)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
    }

    private func earnedLine(_ date: Date) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "calendar")
            Text("Earned on \(date.formatted(date: .long, time: .shortened))")
        }
        .font(AppTypography.callout)
        .foregroundStyle(AppColors.success)
    }

    private var doneButton: some View {
        Button(action: onDismiss) {
            Text("Done")
                .font(AppTypography.bodyEmphasized)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(AppColors.primary)
    }
}

#Preview("Unlocked") {
    BadgeDetailSheet(
        badge: Badge(
            id: BadgeKind.streak7.id,
            name: BadgeKind.streak7.displayName,
            description: BadgeKind.streak7.description,
            iconName: BadgeKind.streak7.iconName,
            unlockedAt: .now
        ),
        onDismiss: {}
    )
}

#Preview("Locked") {
    BadgeDetailSheet(
        badge: Badge(
            id: BadgeKind.completed50.id,
            name: BadgeKind.completed50.displayName,
            description: BadgeKind.completed50.description,
            iconName: BadgeKind.completed50.iconName
        ),
        onDismiss: {}
    )
}
