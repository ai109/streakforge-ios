//
//  XPGainOverlay.swift
//  StreakForge
//
//  The "+XX XP" floating label that animates up and fades out after a
//  successful completion.
//

import SwiftUI

/// A floating, ephemeral "+XX XP" label.
///
/// Placed as an overlay on Today (so it floats above the cards and
/// scroll content) and re-keyed on `event.id` so each new event triggers
/// a fresh animation, even when the awarded amount is identical to the
/// previous one.
///
/// Renders nothing when `event` is `nil`, so the parent can pass through
/// the optional from the view-model directly without conditionals.
struct XPGainOverlay: View {
    let event: XPGainEvent?

    var body: some View {
        ZStack {
            if let event {
                XPGainLabel(amount: event.amount)
                    // .id(_:) is what makes the same view "fresh" per
                    // event — without it, an event with the same `amount`
                    // wouldn't re-run the onAppear animation.
                    .id(event.id)
                    // Scale-in transition adds a satisfying pop on the way
                    // in; the upward translate happens inside XPGainLabel.
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: event?.id)
    }
}

/// The label itself. Split out so the appearance animation has a clean
/// `onAppear` site to drive `offset` and `opacity` from.
private struct XPGainLabel: View {
    let amount: Int

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Label("+\(amount) XP", systemImage: "bolt.fill")
            .font(AppTypography.numericInline)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.flameGradient, in: Capsule())
            .appShadow(.elevated)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                // Two staggered animations: a quick float-up driven by a
                // long, eased curve, plus a fade that runs almost as
                // long but starts a moment later. Together they read as
                // "rises then dissipates" rather than "moves then
                // disappears" — the latter feels abrupt.
                withAnimation(.easeOut(duration: 1.4)) {
                    offset = -100
                }
                withAnimation(.easeIn(duration: 0.8).delay(0.6)) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    XPGainOverlay(event: XPGainEvent(id: UUID(), amount: 32))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
}
