//
//  RootView.swift
//  StreakForge
//
//  Top-level view of the app. Currently a branded placeholder — Step 5
//  will replace its body with the real 5-tab navigation shell.
//

import SwiftUI

/// The root SwiftUI view installed by `StreakForgeApp`.
///
/// During Step 1 this view exists to (a) prove that the new theme tokens
/// (`AppColors`, `AppTypography`, `AppSpacing`) are wired up correctly and
/// (b) replace Xcode's default `ContentView` placeholder with something
/// that already feels on-brand. The layout will be discarded in Step 5
/// when the `TabView` shell lands.
struct RootView: View {
    var body: some View {
        ZStack {
            // Background goes edge-to-edge (under the status bar and home
            // indicator) so the app feels like a single continuous canvas
            // rather than a sheet on top of system chrome.
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Brand mark — flame inside a soft gradient halo. SF Symbol
                // is used here because it scales perfectly with Dynamic Type
                // and inherits color from the gradient overlay below.
                ZStack {
                    Circle()
                        .fill(AppColors.flameGradient)
                        .frame(width: 144, height: 144)
                        .appShadow(.elevated)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 72, weight: .bold))
                        // White on the gradient guarantees enough contrast
                        // in both light and dark modes — the gradient itself
                        // already shifts subtly with the appearance.
                        .foregroundStyle(.white)
                        // Symbol-effect adds a gentle pulse so the placeholder
                        // doesn't feel inert; will be removed with the screen.
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(spacing: AppSpacing.sm) {
                    Text("StreakForge")
                        .font(AppTypography.displayLarge)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Forge your streak, one day at a time.")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }

                Spacer()

                // Tiny build-stage marker — visible only while we're in
                // the early scaffolding steps. It will be deleted in Step 5
                // along with the rest of this placeholder.
                Text("Step 1 — theme & structure")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
    }
}

#Preview("Light") {
    RootView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RootView()
        .preferredColorScheme(.dark)
}
