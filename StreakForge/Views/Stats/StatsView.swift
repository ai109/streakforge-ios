//
//  StatsView.swift
//  StreakForge
//
//  The Stats tab — summary cards, weekly/monthly activity chart,
//  per-category breakdown.
//

import SwiftUI
import SwiftData

/// The Stats tab.
///
/// Pure view-on-data: every value is derived from `@Query` results via
/// `StatsData.compute(...)`. There's no view-model because there's no
/// transient UI state worth abstracting — the only piece of local state
/// is the chart's Week/Month picker, which lives in `@State` right here.
struct StatsView: View {

    @Query(sort: \DailyChallenge.date, order: .reverse)
    private var allDailyChallenges: [DailyChallenge]

    @Query private var allTemplates: [ChallengeTemplate]

    @State private var range: TimeRange = .week

    /// The two windows the activity chart can show. Modeled as an enum
    /// (rather than a free-text or two booleans) so the picker, the
    /// label, and the day-count are all derived from one source.
    enum TimeRange: String, CaseIterable, Identifiable {
        case week  = "Week"
        case month = "Month"

        var id: String { rawValue }

        /// Number of days in the chart window.
        var days: Int {
            switch self {
            case .week:  7
            case .month: 30
            }
        }
    }

    /// The full snapshot for the current state. Recomputed every body
    /// invocation — cheap (linear in row count, ≤30 rows in practice)
    /// and means we don't need to remember to invalidate anything when
    /// SwiftData changes.
    private var stats: StatsData {
        StatsData.compute(
            challenges: allDailyChallenges,
            templates: allTemplates,
            days: range.days
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if stats.totalCompleted == 0 && stats.totalSkipped == 0 {
                    // Empty state — reusing PlaceholderScreen with a
                    // friendlier subtitle than "Coming in step N".
                    PlaceholderScreen(
                        title: "No stats yet",
                        iconName: "chart.bar.xaxis",
                        subtitle: "Complete a challenge to start building your activity history.",
                        stepHint: nil
                    )
                } else {
                    contentScrollView
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: Content

    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                summaryRow
                activitySection
                categorySection
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.lg)
        }
    }

    private var summaryRow: some View {
        // Three colored cards; uses semantic colors rather than category
        // colors because these are *meta* stats (about all categories).
        HStack(spacing: AppSpacing.sm) {
            SummaryCard(
                iconName: "checkmark.seal.fill",
                value: "\(stats.totalCompleted)",
                label: stats.totalCompleted == 1 ? "Completed" : "Completed",
                tint: AppColors.primary
            )
            SummaryCard(
                iconName: "percent",
                value: "\(Int((stats.completionRate * 100).rounded()))%",
                label: "Completion",
                tint: AppColors.success
            )
            SummaryCard(
                iconName: "calendar",
                value: "\(stats.periodCount)",
                label: range == .week ? "This week" : "This month",
                tint: AppColors.accent
            )
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Activity")
                    .font(AppTypography.titleMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Picker("Range", selection: $range) {
                    ForEach(TimeRange.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                // Picker change is purely visual; an animated transition
                // on the chart would be nice but Charts already
                // interpolates the bars across `data` changes for free.
            }

            CompletionChart(data: stats.dailyCompletions)
                .frame(height: 220)
                .padding(AppSpacing.md)
                .background(
                    AppColors.surface,
                    in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                )
                .appShadow(.card)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("By category")
                .font(AppTypography.titleMedium)
                .foregroundStyle(AppColors.textPrimary)

            CategoryBreakdown(rows: stats.categoryCompletions)
                .padding(AppSpacing.md)
                .background(
                    AppColors.surface,
                    in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                )
                .appShadow(.card)
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [
            ChallengeTemplate.self,
            DailyChallenge.self,
            UserProgress.self,
            Badge.self
        ], inMemory: true)
}
