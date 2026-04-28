//
//  HistoryRow.swift
//  StreakForge
//
//  One row in the History list — category icon, title, metadata, status.
//

import SwiftUI

/// A single past-challenge entry in the History list.
///
/// Layout: category icon disc on the leading edge (color-coded so a
/// glance down the list shows category mix), title + metadata in the
/// middle, status icon trailing. The completion time is folded into the
/// metadata line rather than getting its own column — there's only ever
/// one timestamp to show, and dedicated columns waste horizontal space.
struct HistoryRow: View {

    let challenge: DailyChallenge
    let template: ChallengeTemplate

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            categoryDisc
            titleAndMetadata
            Spacer(minLength: 0)
            statusIcon
        }
        .padding(.vertical, AppSpacing.xs)
        // Skipped rows fade slightly so the eye is drawn to completed
        // entries — the win column matters more than the miss column.
        .opacity(challenge.status == .skipped ? 0.7 : 1.0)
    }

    // MARK: Subviews

    private var categoryDisc: some View {
        ZStack {
            Circle()
                .fill(template.category.color.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: template.category.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(template.category.color)
        }
    }

    private var titleAndMetadata: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(template.title)
                .font(AppTypography.bodyEmphasized)
                .foregroundStyle(AppColors.textPrimary)
                // Strike-through skipped titles for a quick visual "did
                // not do" cue — same convention used on the Today card
                // for completed challenges. Re-using the affordance
                // keeps the visual language consistent across screens.
                .strikethrough(challenge.status == .skipped, color: AppColors.textMuted)
                .lineLimit(2)

            metadataLine
        }
    }

    private var metadataLine: some View {
        // Single horizontal line of small dots-separated facts. The
        // dot separator comes from string interpolation rather than a
        // SwiftUI separator view because it lays out as one wrapping
        // text run — much friendlier to long titles than nested HStacks
        // would be.
        HStack(spacing: AppSpacing.xs) {
            Text(template.difficulty.displayName)
                .foregroundStyle(template.difficulty.color)

            Text("·")
                .foregroundStyle(AppColors.textMuted)

            Text("\(template.estMinutes) min")
                .foregroundStyle(AppColors.textMuted)

            if let completedAt = challenge.completedAt {
                Text("·")
                    .foregroundStyle(AppColors.textMuted)
                Text(completedAt.formatted(date: .omitted, time: .shortened))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .font(AppTypography.caption)
    }

    private var statusIcon: some View {
        Image(systemName: challenge.status.iconName)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(challenge.status.color)
    }
}

#Preview {
    let template = ChallengeTemplate(
        title: "Read 5 pages of a book",
        description: "…",
        category: .study,
        difficulty: .easy,
        estMinutes: 10
    )
    let completed = DailyChallenge(
        date: .now, templateId: template.id,
        status: .completed, completedAt: .now
    )
    let skipped = DailyChallenge(
        date: .now, templateId: template.id,
        status: .skipped
    )
    return VStack {
        HistoryRow(challenge: completed, template: template)
        HistoryRow(challenge: skipped, template: template)
    }
    .padding()
    .background(AppColors.background)
}
