//
//  BadgesView.swift
//  StreakForge
//
//  The Badges tab — header card + adaptive grid of locked/unlocked tiles
//  + tap-to-detail sheet.
//

import SwiftUI
import SwiftData

/// The Badges tab.
///
/// All ten badges are persisted (the seeder inserts the locked rows on
/// first launch — see `SeedDataService`), so this view is a pure read:
/// `@Query` everything, sort, render, present a sheet on tap.
///
/// No view-model — the only ephemeral state is "which badge's detail is
/// open", which lives in `@State` directly via a sheet binding.
struct BadgesView: View {

    @Query private var allBadges: [Badge]

    /// The currently-presented detail sheet, if any. Using `Badge?` as
    /// the sheet item gives us automatic dismiss when set to nil and
    /// preserves the full badge through the presentation.
    @State private var selectedBadge: Badge?

    /// Adaptive grid columns — fits 2 across on most iPhones, 3+ on iPads
    /// or large iPhones in landscape. `minimum: 150` keeps tiles legible
    /// at all device sizes.
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: AppSpacing.md)]

    /// Badges sorted unlocked-first (newest unlocks at top), then locked
    /// in `BadgeKind` enum order.
    ///
    /// Sorting by status first means the user enters the screen and
    /// immediately sees what they've earned, rather than scanning past
    /// a wall of locked tiles to find their three trophies.
    private var sortedBadges: [Badge] {
        allBadges.sorted { lhs, rhs in
            switch (lhs.unlockedAt, rhs.unlockedAt) {
            case (let l?, let r?):
                // Both unlocked: newest first.
                return l > r
            case (_?, nil):
                return true   // unlocked precedes locked
            case (nil, _?):
                return false
            case (nil, nil):
                // Both locked: keep BadgeKind enum order so the locked
                // section reads in the same sequence as the spec
                // (First Step → 3-Day Streak → … → Category Specialist).
                let li = BadgeKind.allCases.firstIndex { $0.id == lhs.id } ?? .max
                let ri = BadgeKind.allCases.firstIndex { $0.id == rhs.id } ?? .max
                return li < ri
            }
        }
    }

    private var unlockedCount: Int {
        allBadges.lazy.filter { $0.isUnlocked }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if allBadges.isEmpty {
                    // Defensive empty state — should never happen because
                    // the seeder inserts all 10 badges at first launch,
                    // but rendering a placeholder beats rendering nothing
                    // if a future migration ever clears the table.
                    PlaceholderScreen(
                        title: "No badges yet",
                        iconName: "rosette",
                        subtitle: "Badge data hasn't loaded.",
                        stepHint: nil
                    )
                } else {
                    contentScrollView
                }
            }
            .navigationTitle("Badges")
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailSheet(badge: badge) {
                    selectedBadge = nil
                }
            }
            // Soft tap when a tile is tapped (sheet opens). The trigger
            // changes when `selectedBadge` becomes non-nil.
            .sensoryFeedback(.impact(weight: .light), trigger: selectedBadge?.id)
        }
    }

    // MARK: Content

    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                BadgesHeader(
                    unlockedCount: unlockedCount,
                    totalCount: allBadges.count
                )

                LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                    ForEach(sortedBadges) { badge in
                        Button {
                            selectedBadge = badge
                        } label: {
                            BadgeTile(badge: badge)
                        }
                        // Plain style strips the default button chrome
                        // (blue background, padding) so the tile renders
                        // as designed. .accessibilityAddTraits keeps it
                        // recognized as tappable to VoiceOver.
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.lg)
        }
    }
}

#Preview {
    BadgesView()
        .modelContainer(for: [
            ChallengeTemplate.self,
            DailyChallenge.self,
            UserProgress.self,
            Badge.self
        ], inMemory: true)
}
