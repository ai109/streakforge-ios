//
//  TodayViewModel.swift
//  StreakForge
//
//  Orchestrates the Today screen: bootstrap, complete/skip/swap actions,
//  and the ephemeral animation/error state that doesn't belong in
//  SwiftData (toasts, XP-gain pulses, haptic triggers).
//

import Foundation
import SwiftData
import SwiftUI

/// View-model for `TodayView`.
///
/// The split between view-model and view follows the spec's "MVVM-ish"
/// guidance:
/// * The **view** owns SwiftData reads via `@Query` so updates flow
///   automatically when the store changes.
/// * The **view-model** owns *transient* UI state — animation triggers,
///   toast contents, last-action timestamps for haptics — and forwards
///   actions to the three services.
///
/// Persistent state (XP, streak, badge unlock timestamps) lives only in
/// SwiftData; the view-model never duplicates it.
@MainActor
@Observable
final class TodayViewModel {

    // MARK: Services
    //
    // Held as properties (not freshly constructed at every call) so tests
    // can swap them out for fakes via `init(challengeService:…)`. Marked
    // `var` rather than `let` for the same reason — letting a test mutate
    // `now` after construction is convenient.

    var challengeService: ChallengeService
    var progressService: ProgressService
    var badgeService: BadgeService

    // MARK: Ephemeral UI state

    /// Triggers the floating "+XX XP" overlay. Set to a fresh event with
    /// a new `id` on every completion — the overlay keys on the id so an
    /// identical XP amount fired twice in a row still re-runs the
    /// animation (a bare Int wouldn't, since the value didn't change).
    var xpGainEvent: XPGainEvent?

    /// Badges that just transitioned from locked to unlocked. The view
    /// shows a toast when this is non-empty; the user dismisses by
    /// tapping it (or it auto-dismisses after a few seconds).
    var newlyUnlockedBadges: [Badge] = []

    /// Non-nil when the most recent swap couldn't proceed (out of budget,
    /// no eligible template). The view binds an alert / toast to it.
    var swapErrorMessage: String?

    // MARK: Haptic triggers
    //
    // SwiftUI's `.sensoryFeedback(_, trigger:)` modifier fires when its
    // trigger value changes. We use Date-typed counters because they're
    // (a) Equatable, (b) monotonically unique, and (c) directly inspectable
    // in the debugger. A bare `Int` increment would also work but reads
    // less obvious in logs.

    private(set) var lastSuccessAt: Date?
    private(set) var lastImpactAt: Date?
    private(set) var lastWarningAt: Date?

    // MARK: Init

    /// Designated init.
    ///
    /// Default arguments are `nil` (rather than `ChallengeService()` etc.)
    /// because parameter-default expressions are type-checked outside the
    /// init's MainActor-isolated body, which clashes with the project's
    /// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` setting. Constructing
    /// the defaults inside the body sidesteps that without losing the
    /// "common case takes no arguments" ergonomic.
    init(
        challengeService: ChallengeService? = nil,
        progressService: ProgressService? = nil,
        badgeService: BadgeService? = nil
    ) {
        self.challengeService = challengeService ?? ChallengeService()
        self.progressService = progressService ?? ProgressService()
        self.badgeService = badgeService ?? BadgeService()
    }

    // MARK: Bootstrap

    /// Ensures persistent state is consistent with "today":
    /// * Daily challenges exist for today.
    /// * Swap budget has been rolled over if we crossed midnight.
    /// * `UserProgress` row exists (created on first call).
    ///
    /// Cheap to call repeatedly — `ensureTodayExists` is a no-op when
    /// today's rows are already present, and `resetSwapBudgetIfNeeded`
    /// is a no-op when the budget is already on today's date. The view
    /// calls this on `.task` and again on every transition to `.active`,
    /// which together handle "fresh launch" and "user came back across
    /// midnight" without needing a midnight timer.
    func bootstrap(in context: ModelContext) {
        progressService.resetSwapBudgetIfNeeded(in: context)
        challengeService.ensureTodayExists(in: context)
        // Side-effect: `current(in:)` creates the singleton UserProgress
        // row on first call. Calling it here means the ProgressHeader's
        // `@Query` finds a row to render rather than briefly being empty.
        _ = progressService.current(in: context)
    }

    // MARK: Actions

    /// Records a completion: marks the challenge done, awards XP, runs
    /// badge evaluation, and fires the relevant animations + haptic.
    func complete(
        _ challenge: DailyChallenge,
        template: ChallengeTemplate,
        in context: ModelContext
    ) {
        let xp = progressService.recordCompletion(
            of: challenge,
            difficulty: template.difficulty,
            in: context
        )
        // Order matters: complete first so the snapshot the evaluator
        // builds includes this completion's bumped totalCompleted /
        // streak / completion record.
        let unlocked = badgeService.evaluate(in: context)

        xpGainEvent = XPGainEvent(id: UUID(), amount: xp)
        if !unlocked.isEmpty {
            // Append rather than replace so back-to-back completions
            // that each unlock something don't lose toasts.
            newlyUnlockedBadges.append(contentsOf: unlocked)
        }
        lastSuccessAt = .now
    }

    /// Records a skip: marks the challenge skipped, no XP/streak change,
    /// fires a light haptic.
    func skip(_ challenge: DailyChallenge, in context: ModelContext) {
        progressService.recordSkip(of: challenge, in: context)
        lastImpactAt = .now
    }

    /// Attempts a swap. Surfaces an error string (and a warning haptic)
    /// when the swap can't proceed — see `SwapResult` for the cases.
    func swap(_ challenge: DailyChallenge, in context: ModelContext) {
        let result = challengeService.swap(challenge, in: context)
        switch result {
        case .swapped:
            lastImpactAt = .now
        case .budgetExhausted:
            swapErrorMessage = "You've already used your swap for today. Come back tomorrow!"
            lastWarningAt = .now
        case .notPending:
            // The UI hides the swap button on non-pending cards, so this
            // branch is only reachable if the user hits a stale view.
            // No toast — silently no-op rather than confuse.
            break
        case .noEligibleTemplate:
            swapErrorMessage = "No fresh challenges available right now."
            lastWarningAt = .now
        }
    }

    /// Pops the front-most badge from the toast queue. The view calls
    /// this on tap or auto-dismiss timeout.
    func dismissTopBadgeToast() {
        guard !newlyUnlockedBadges.isEmpty else { return }
        newlyUnlockedBadges.removeFirst()
    }

    /// Clears the swap-error message. Bound by the view's alert/toast.
    func clearSwapError() {
        swapErrorMessage = nil
    }
}

/// One discrete XP-gain animation event.
///
/// The `id` is what the overlay's `.id(_)` modifier keys on so SwiftUI
/// recreates the view (and re-runs the animation) for every event,
/// even if the XP `amount` happens to match the previous one.
struct XPGainEvent: Identifiable, Equatable {
    let id: UUID
    let amount: Int
}
