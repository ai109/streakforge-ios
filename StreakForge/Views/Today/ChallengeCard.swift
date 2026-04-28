//
//  ChallengeCard.swift
//  StreakForge
//
//  One challenge in the Today list — title, description, metadata pills,
//  and the Complete / Skip / Swap action row.
//

import SwiftUI

/// One row in the Today list. Renders the challenge's metadata, copy, and
/// action buttons; collapses the buttons into a status indicator once the
/// challenge is no longer pending.
///
/// Pure view — no SwiftData, no service calls. Actions are surfaced as
/// closures so the parent (`TodayView`) coordinates with the view-model
/// and `ModelContext`. This is what makes the card trivially previewable
/// with a hand-built `ChallengeTemplate`.
struct ChallengeCard: View {

    let challenge: DailyChallenge
    let template: ChallengeTemplate
    let canSwap: Bool
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onSwap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Vertical color strip on the leading edge — instant visual
            // category cue without taking content space. Same width as
            // a typical iOS list separator inset for visual familiarity.
            Rectangle()
                .fill(template.category.color)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                metadataRow
                titleAndDescription
                if challenge.status == .pending {
                    actionRow
                } else {
                    statusRow
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .appShadow(.card)
        // De-emphasize completed/skipped cards — they stay full-size
        // (so layout doesn't shift mid-tap) but visually recede so the
        // user's eye is drawn to anything still pending.
        .opacity(challenge.status == .pending ? 1.0 : 0.6)
        // Animate the opacity / button morph so the state change feels
        // intentional rather than instant.
        .animation(.smooth(duration: 0.25), value: challenge.status)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    // MARK: Subviews

    private var metadataRow: some View {
        HStack(spacing: AppSpacing.sm) {
            CategoryChip(category: template.category)
            DifficultyChip(difficulty: template.difficulty)
            Spacer()
            Label("\(template.estMinutes) min", systemImage: "clock")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .labelStyle(.titleAndIcon)
        }
    }

    private var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(template.title)
                .font(AppTypography.titleSmall)
                .foregroundStyle(AppColors.textPrimary)
                // Strike-through completed/skipped titles for a quick
                // visual confirmation that an action stuck.
                .strikethrough(challenge.status != .pending, color: AppColors.textMuted)

            Text(template.challengeDescription)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionRow: some View {
        HStack(spacing: AppSpacing.sm) {
            // Complete is the primary CTA — full-width, brand orange,
            // takes whatever horizontal space the secondary buttons
            // don't claim.
            Button(action: onComplete) {
                Label("Complete", systemImage: "checkmark")
                    .font(AppTypography.bodyEmphasized)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColors.primary)

            // Skip + Swap as compact icon-only secondaries. The icon
            // language ("forward" / "circular arrows") is conventional
            // enough that no labels are needed at this size.
            Button(action: onSkip) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(AppColors.textSecondary)
            .accessibilityLabel("Skip")

            Button(action: onSwap) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(canSwap ? template.category.color : AppColors.textMuted)
            .disabled(!canSwap)
            .accessibilityLabel(canSwap ? "Swap" : "Swap (used today)")
        }
    }

    private var statusRow: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: challenge.status.iconName)
                .font(.system(size: 14, weight: .semibold))
            Text(challenge.status.displayName)
                .font(AppTypography.captionSmall)
        }
        .foregroundStyle(challenge.status.color)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule().fill(challenge.status.color.opacity(0.12))
        )
    }
}

// MARK: - Chips

/// Small category badge — colored dot + name. Reused on the Today card and
/// (eventually) the History list, so it lives here ready to be promoted to
/// `Views/Components/` if a third caller appears.
private struct CategoryChip: View {
    let category: ChallengeCategory

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: category.iconName)
                .font(.system(size: 11, weight: .bold))
            Text(category.displayName)
                .font(AppTypography.captionSmall)
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 4)
        .background(
            // 12% tint of the category color reads as "category-colored"
            // without dominating the card visually.
            Capsule().fill(category.color.opacity(0.14))
        )
    }
}

/// Small difficulty badge — uses the difficulty's color (green/amber/red)
/// for an at-a-glance hardness cue.
private struct DifficultyChip: View {
    let difficulty: ChallengeDifficulty

    var body: some View {
        Text(difficulty.displayName)
            .font(AppTypography.captionSmall)
            .foregroundStyle(difficulty.color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(difficulty.color.opacity(0.14))
            )
    }
}

#Preview("Pending") {
    let template = ChallengeTemplate(
        title: "Read 5 pages of a book",
        description: "Pick up a physical or e-book and read at least five pages.",
        category: .study,
        difficulty: .easy,
        estMinutes: 10
    )
    let challenge = DailyChallenge(date: .now, templateId: template.id)
    return ChallengeCard(
        challenge: challenge,
        template: template,
        canSwap: true,
        onComplete: {}, onSkip: {}, onSwap: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Completed") {
    let template = ChallengeTemplate(
        title: "Take a 15-minute walk outside",
        description: "Get out of the building, no podcast required — just walk.",
        category: .health,
        difficulty: .medium,
        estMinutes: 15
    )
    let challenge = DailyChallenge(
        date: .now,
        templateId: template.id,
        status: .completed,
        completedAt: .now
    )
    return ChallengeCard(
        challenge: challenge,
        template: template,
        canSwap: false,
        onComplete: {}, onSkip: {}, onSwap: {}
    )
    .padding()
    .background(AppColors.background)
}
