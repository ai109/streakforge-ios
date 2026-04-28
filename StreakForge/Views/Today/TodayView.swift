//
//  TodayView.swift
//  StreakForge
//
//  The Today tab — daily challenge feed with complete / skip / swap,
//  XP-gain animation, and badge-unlock toasts.
//

import SwiftUI
import SwiftData

/// The Today tab.
///
/// Composition: header (streak + XP) → 3 challenge cards → either an
/// "all done" celebration or a swap-budget hint. Above all of that, two
/// non-blocking overlays float in: the XP-gain pulse and the badge-unlock
/// toast.
///
/// Data flow: SwiftData `@Query` for everything persistent; the
/// `TodayViewModel` owns the ephemeral toast/animation state. Bootstrap
/// (creating today's rows + rolling the swap budget) runs both on
/// `.task` and on every transition to `.active`, which together cover
/// "fresh launch" and "user came back across midnight" without a timer.
struct TodayView: View {

    // MARK: Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // MARK: Persistent state (read via @Query so updates auto-flow)

    /// All daily challenges, newest first. We filter to "today" in
    /// computed property `todayChallenges` rather than at the query
    /// level — `@Query`'s predicate macro is finicky around captured
    /// `Date` values, and the in-memory filter is free at this scale.
    @Query(sort: \DailyChallenge.date, order: .reverse)
    private var allDailyChallenges: [DailyChallenge]

    @Query private var allTemplates: [ChallengeTemplate]
    @Query private var allProgress: [UserProgress]

    // MARK: Ephemeral state

    @State private var viewModel = TodayViewModel()

    // MARK: Derived

    private var today: Date { Calendar.current.startOfDay(for: .now) }

    private var todayChallenges: [DailyChallenge] {
        allDailyChallenges
            .filter { $0.date == today }
            // Stable order within the day. Sorting by id keeps the cards
            // from reshuffling on every state mutation — important
            // because the card the user just tapped should stay where it
            // was, not jump to the bottom because its `status` changed.
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private var templateByID: [UUID: ChallengeTemplate] {
        Dictionary(uniqueKeysWithValues: allTemplates.map { ($0.id, $0) })
    }

    private var progress: UserProgress? { allProgress.first }

    private var canSwap: Bool { (progress?.swapsUsedToday ?? 1) < 1 }

    private var allDone: Bool {
        !todayChallenges.isEmpty
            && todayChallenges.allSatisfy { $0.status != .pending }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppColors.background.ignoresSafeArea()
                contentScrollView
                overlayLayer
            }
            .navigationTitle("Today")
            .task { viewModel.bootstrap(in: modelContext) }
            .onChange(of: scenePhase) { _, new in
                // Re-bootstrap when the user comes back to the app — picks
                // up "the date changed while we were backgrounded" without
                // needing a midnight timer.
                if new == .active { viewModel.bootstrap(in: modelContext) }
            }
            // Modern haptic API — `trigger` fires when its value changes,
            // and the view-model bumps a Date for each kind of feedback.
            .sensoryFeedback(.success, trigger: viewModel.lastSuccessAt)
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.lastImpactAt)
            .sensoryFeedback(.warning, trigger: viewModel.lastWarningAt)
        }
    }

    // MARK: - Subviews

    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                if let progress {
                    ProgressHeader(progress: progress)
                }

                challengeStack

                if allDone {
                    AllDoneFooter(streak: progress?.currentStreak ?? 0)
                } else {
                    swapHint
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.lg)
        }
    }

    private var challengeStack: some View {
        VStack(spacing: AppSpacing.md) {
            // Loading-flicker safety: if we somehow have zero rows for
            // today (the bootstrap hasn't completed yet on a brand-new
            // install), show the same placeholder skeleton as a real
            // empty state. In practice this lasts <100ms.
            if todayChallenges.isEmpty {
                emptySkeleton
            } else {
                ForEach(todayChallenges) { challenge in
                    if let template = templateByID[challenge.templateId] {
                        ChallengeCard(
                            challenge: challenge,
                            template: template,
                            canSwap: canSwap && challenge.status == .pending,
                            onComplete: { viewModel.complete(challenge, template: template, in: modelContext) },
                            onSkip:     { viewModel.skip(challenge, in: modelContext) },
                            onSwap:     { viewModel.swap(challenge, in: modelContext) }
                        )
                        // Per-row id so the swap mutation (which keeps
                        // the same DailyChallenge.id but changes the
                        // templateId) animates as a content swap rather
                        // than a teardown.
                        .id(challenge.id)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .animation(.smooth, value: todayChallenges.map { $0.templateId })
    }

    private var emptySkeleton: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(AppColors.surface)
                    .frame(height: 168)
                    .appShadow(.card)
                    // The pulse opacity gives a subtle "loading" feel
                    // without a spinner — quieter and closer to the rest
                    // of the brand language.
                    .opacity(0.8)
            }
        }
    }

    private var swapHint: some View {
        // The hint only earns its place once at least one challenge is
        // pending and a swap is still available — otherwise it's noise.
        Group {
            if !todayChallenges.isEmpty, canSwap {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("1 swap available today")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    // MARK: Overlays

    @ViewBuilder
    private var overlayLayer: some View {
        VStack(spacing: AppSpacing.sm) {
            // Stack toasts vertically — back-to-back unlocks (e.g.
            // First Step + 10 Completed at the same milestone) each get
            // their own banner instead of being squashed into one.
            ForEach(viewModel.newlyUnlockedBadges) { badge in
                Toast(
                    title: "Badge unlocked: \(badge.name)",
                    message: badge.badgeDescription,
                    tint: AppColors.success,
                    autoDismissAfter: 3.5,
                    onDismiss: { viewModel.dismissTopBadgeToast() }
                ) {
                    Image(systemName: badge.iconName)
                        .font(.system(size: 18, weight: .bold))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let message = viewModel.swapErrorMessage {
                Toast(
                    title: "Heads up",
                    message: message,
                    tint: AppColors.warning,
                    autoDismissAfter: 3.0,
                    onDismiss: viewModel.clearSwapError
                ) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .padding(.top, AppSpacing.sm)
        .animation(.smooth, value: viewModel.newlyUnlockedBadges.count)
        .animation(.smooth, value: viewModel.swapErrorMessage)
        // XP-gain floats above the toasts, centered vertically — it's a
        // brief celebration, not a notification, and shouldn't compete
        // with toasts for the same screen real estate.
        .overlay {
            XPGainOverlay(event: viewModel.xpGainEvent)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [
            ChallengeTemplate.self,
            DailyChallenge.self,
            UserProgress.self,
            Badge.self
        ], inMemory: true)
}
