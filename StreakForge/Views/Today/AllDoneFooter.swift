//
//  AllDoneFooter.swift
//  StreakForge
//
//  Footer shown below the challenge cards once all three are
//  completed/skipped. Confirms the day is "closed" and reinforces the
//  streak.
//

import SwiftUI

/// "You've done everything for today" celebration footer.
///
/// Appears below the three challenge cards once each is no longer
/// pending. Wrapping a positive note around a finished day is a small
/// behavioral nudge — it acknowledges the user's effort rather than
/// leaving them on a screen full of faded cards with no closing beat.
struct AllDoneFooter: View {

    /// Current streak — included in the message because seeing it
    /// reinforces the "keep coming back" loop.
    let streak: Int

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.success)

            Text("You're done for today")
                .font(AppTypography.titleSmall)
                .foregroundStyle(AppColors.textPrimary)

            Text(streakMessage)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.lg)
        .background(
            AppColors.success.opacity(0.10),
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
    }

    /// Streak-aware copy — keeps the day-zero case from sounding hollow
    /// ("you have a 0-day streak!") by branching into three tiers.
    private var streakMessage: String {
        switch streak {
        case 0:    "Come back tomorrow to start a new streak."
        case 1:    "That's day 1 of your new streak. See you tomorrow!"
        default:   "You're on a \(streak)-day streak. Keep it going!"
        }
    }
}

#Preview("Streak 7") {
    AllDoneFooter(streak: 7)
        .padding()
        .background(AppColors.background)
}

#Preview("Day 1") {
    AllDoneFooter(streak: 1)
        .padding()
        .background(AppColors.background)
}
