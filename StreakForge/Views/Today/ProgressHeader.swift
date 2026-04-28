//
//  ProgressHeader.swift
//  StreakForge
//
//  Hero card at the top of Today: streak (with flame), total XP, best.
//

import SwiftUI

/// The flame-gradient hero card at the top of the Today screen.
///
/// Designed as the visual anchor of the screen — large streak number on a
/// warm gradient so a glance at the top of the app instantly communicates
/// "what state am I in".
///
/// Reads its values directly from the `UserProgress` row (passed in,
/// not queried internally) so this view has zero dependencies on
/// SwiftData and stays trivially previewable with a sample model.
struct ProgressHeader: View {

    let progress: UserProgress

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Top: streak number + label. The flame icon flanks the
            // number rather than sitting above it because the eye
            // groups them as one unit ("7-day streak") that way.
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                // Symbol-effect.pulse animates the flame subtly while a
                // streak is active, going still when streak == 0 — a
                // small reward for keeping the chain going.
                Image(systemName: progress.currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: progress.currentStreak > 0 ? .repeating : .nonRepeating)

                Text("\(progress.currentStreak)")
                    .font(AppTypography.displayLarge)
                    .foregroundStyle(.white)

                Text(progress.currentStreak == 1 ? "day" : "days")
                    .font(AppTypography.titleMedium)
                    .foregroundStyle(.white.opacity(0.85))
            }

            // Hairline divider — keeps the bottom row visually distinct
            // from the streak hero without looking like a separate card.
            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, AppSpacing.lg)

            // Bottom: XP and best-streak pills.
            HStack(spacing: AppSpacing.lg) {
                StatPill(
                    iconName: "bolt.fill",
                    value: "\(progress.totalXP)",
                    label: "XP"
                )

                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 1, height: 32)

                StatPill(
                    iconName: "trophy.fill",
                    value: "\(progress.bestStreak)",
                    label: progress.bestStreak == 1 ? "best day" : "best days"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.lg)
        .background(
            // The flame gradient is the strongest single brand cue we
            // have — putting it on the most-glanced element of the
            // most-used screen pays the highest visual dividend.
            AppColors.flameGradient,
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .appShadow(.elevated)
    }
}

/// One number+label cluster inside `ProgressHeader`. Pulled out so the
/// XP and best-streak slots stay byte-identical without accidental drift.
private struct StatPill: View {
    let iconName: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AppTypography.numericInline)
                    .foregroundStyle(.white)
                Text(label)
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    let sample = UserProgress(
        totalXP: 245,
        currentStreak: 7,
        bestStreak: 12,
        lastCompletionDate: .now,
        totalCompleted: 18
    )
    return ProgressHeader(progress: sample)
        .padding()
        .background(AppColors.background)
}
