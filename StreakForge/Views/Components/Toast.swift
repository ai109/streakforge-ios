//
//  Toast.swift
//  StreakForge
//
//  Reusable banner that slides in from the top. Used by Today for badge
//  unlock notifications and swap errors.
//

import SwiftUI

/// A short-lived banner that slides down from the top safe area.
///
/// Built generic over its content so the same component handles both
/// "Badge unlocked: First Step" (success-tinted, with a tap action) and
/// "You've used your swap" (warning-tinted) without the call site having
/// to wire up the slide/transition logic twice.
///
/// Auto-dismisses after `autoDismissAfter` seconds. The caller passes a
/// closure that will be invoked when that timer fires (or when the toast
/// is tapped) so the parent can clear whatever state spawned it.
struct Toast<Leading: View>: View {

    let title: String
    let message: String?
    /// Background tint of the banner. Pass a semantic color from
    /// `AppColors` (success / warning / etc.) so the toast carries
    /// meaning at a glance even before the user reads it.
    let tint: Color
    let autoDismissAfter: TimeInterval
    let onDismiss: () -> Void
    @ViewBuilder let leading: () -> Leading

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            leading()
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.18), in: Circle())
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundStyle(AppColors.textPrimary)
                if let message {
                    Text(message)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(
            AppColors.surfaceElevated,
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .overlay(
            // Subtle accent stripe along the leading edge, same color as
            // the icon — gives the toast a clear semantic identity even
            // when the user only sees it for a second in their periphery.
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .appShadow(.elevated)
        .padding(.horizontal, AppSpacing.base)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .task {
            // Use try? Task.sleep so a cancellation (parent dismissing
            // the toast manually) cleanly stops the auto-dismiss timer
            // rather than firing a stale `onDismiss` afterwards.
            try? await Task.sleep(for: .seconds(autoDismissAfter))
            // After the sleep, double-check we weren't cancelled before
            // calling `onDismiss` — Task.sleep returns either way on
            // cancellation but the check makes intent explicit.
            if !Task.isCancelled {
                onDismiss()
            }
        }
    }
}

#Preview {
    VStack {
        Toast(
            title: "Badge unlocked: First Step",
            message: "Tap to view in Badges",
            tint: AppColors.success,
            autoDismissAfter: 60,
            onDismiss: {}
        ) {
            Image(systemName: "rosette")
                .font(.system(size: 18, weight: .bold))
        }
        .padding(.top, AppSpacing.xl)

        Spacer()
    }
    .background(AppColors.background)
}
