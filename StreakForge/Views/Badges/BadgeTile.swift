//
//  BadgeTile.swift
//  StreakForge
//
//  One cell in the Badges grid — locked or unlocked variant of a single
//  badge.
//

import SwiftUI

/// Visual representation of one `Badge` in the grid.
///
/// Two visual modes:
/// * **Unlocked** — full-color icon on the flame gradient, success-green
///   border, "Earned X" pill at the bottom, optional NEW indicator if
///   unlocked in the last 24h.
/// * **Locked** — grayscale icon on muted surface, lock-fill corner
///   overlay, "Locked" subtext.
///
/// The visual contrast between the two modes is the point — entering
/// the Badges tab should make it instantly obvious which ones are done
/// and which aren't, with no "is that unlocked?" ambiguity.
struct BadgeTile: View {

    let badge: Badge

    /// True for badges unlocked within the last 24 hours. Drives the
    /// "NEW" indicator so users entering the Badges tab can spot fresh
    /// unlocks without scanning earned-dates.
    private var isFreshlyUnlocked: Bool {
        guard let unlockedAt = badge.unlockedAt else { return false }
        return Date.now.timeIntervalSince(unlockedAt) < 24 * 60 * 60
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            iconView
            textBlock
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            badge.isUnlocked ? AppColors.surface : AppColors.surface.opacity(0.6),
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .overlay(
            // Tinted border doubles the locked/unlocked visual cue —
            // even at a glance from the corner of the eye, the green
            // outline reads as "earned".
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(
                    badge.isUnlocked ? AppColors.success.opacity(0.35) : AppColors.divider,
                    lineWidth: badge.isUnlocked ? 1.5 : 1
                )
        )
        .appShadow(.card)
        .overlay(alignment: .topTrailing) {
            if isFreshlyUnlocked {
                NewIndicator()
                    .padding(AppSpacing.sm)
            }
        }
        // Smooth state transition — if a badge gets unlocked while this
        // tile is on screen (uncommon since users complete on Today,
        // but possible with shared tabs / iPad split-view), the tile
        // morphs rather than snaps.
        .animation(.smooth(duration: 0.4), value: badge.isUnlocked)
    }

    // MARK: Icon

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    badge.isUnlocked
                        ? AnyShapeStyle(AppColors.flameGradient)
                        : AnyShapeStyle(Color.gray.opacity(0.25))
                )
                .frame(width: 72, height: 72)

            Image(systemName: badge.iconName)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(badge.isUnlocked ? .white : Color.gray.opacity(0.5))
                // Bounce when state flips locked→unlocked. SwiftUI's
                // symbol effects key on a value change; using the
                // `unlockedAt` Date as the trigger means it fires
                // exactly once per actual unlock event.
                .symbolEffect(.bounce, value: badge.unlockedAt)
        }
        .overlay(alignment: .bottomTrailing) {
            if !badge.isUnlocked {
                // Lock-fill corner glyph — small but unmistakable, even
                // when the tile is glanced at from across the screen.
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Circle().fill(AppColors.textSecondary))
                    .offset(x: 4, y: 4)
            }
        }
    }

    // MARK: Text

    private var textBlock: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(badge.name)
                .font(AppTypography.titleSmall)
                .foregroundStyle(badge.isUnlocked ? AppColors.textPrimary : AppColors.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if badge.isUnlocked, let date = badge.unlockedAt {
                Text(earnedLabel(date))
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.success)
            } else {
                Text("Locked")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    /// Human-friendly "earned" string. We branch on age because "Earned
    /// today" reads better than "Earned Apr 28, 2026" for fresh unlocks
    /// — and conversely, "5 minutes ago" is too noisy for older ones.
    private func earnedLabel(_ date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        if interval < 24 * 60 * 60 {
            return "Earned today"
        }
        let days = Int(interval / (24 * 60 * 60))
        if days < 7 {
            return "Earned \(days) day\(days == 1 ? "" : "s") ago"
        }
        return "Earned \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

/// The "NEW" pill shown on tiles unlocked in the last 24h.
private struct NewIndicator: View {
    var body: some View {
        Text("NEW")
            .font(AppTypography.captionSmall)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 2)
            .background(Capsule().fill(AppColors.primary))
            // Subtle pulse to draw the eye — repeating, slow, not loud.
            .symbolEffect(.pulse, options: .repeating)
    }
}

#Preview("Unlocked (today)") {
    let badge = Badge(
        id: BadgeKind.firstStep.id,
        name: BadgeKind.firstStep.displayName,
        description: BadgeKind.firstStep.description,
        iconName: BadgeKind.firstStep.iconName,
        unlockedAt: .now
    )
    return BadgeTile(badge: badge)
        .frame(width: 180)
        .padding()
        .background(AppColors.background)
}

#Preview("Unlocked (week ago)") {
    let badge = Badge(
        id: BadgeKind.streak7.id,
        name: BadgeKind.streak7.displayName,
        description: BadgeKind.streak7.description,
        iconName: BadgeKind.streak7.iconName,
        unlockedAt: Calendar.current.date(byAdding: .day, value: -10, to: .now)
    )
    return BadgeTile(badge: badge)
        .frame(width: 180)
        .padding()
        .background(AppColors.background)
}

#Preview("Locked") {
    let badge = Badge(
        id: BadgeKind.completed50.id,
        name: BadgeKind.completed50.displayName,
        description: BadgeKind.completed50.description,
        iconName: BadgeKind.completed50.iconName
    )
    return BadgeTile(badge: badge)
        .frame(width: 180)
        .padding()
        .background(AppColors.background)
}
