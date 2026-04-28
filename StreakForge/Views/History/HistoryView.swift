//
//  HistoryView.swift
//  StreakForge
//
//  The History tab — every completed and skipped challenge, filterable
//  by category and status, grouped by date.
//

import SwiftUI
import SwiftData

/// The History tab.
///
/// Pure view-on-data: `@Query` the relevant rows, filter in-memory, group
/// by date, render as a `List`. Two filter dimensions:
/// * Category — a horizontal chip bar (most-used filter, deserves
///   primary screen real estate).
/// * Status — a toolbar Menu Picker (less frequently changed; auto-shows
///   a checkmark next to the selected option).
///
/// Pending challenges are excluded by definition — those live on Today,
/// not in the historical record.
struct HistoryView: View {

    @Query(sort: \DailyChallenge.date, order: .reverse)
    private var allDailyChallenges: [DailyChallenge]

    @Query private var allTemplates: [ChallengeTemplate]

    @State private var categoryFilter: ChallengeCategory?
    @State private var statusFilter: StatusFilter = .all

    /// The status filter dimension. Modeled as an enum so the menu
    /// picker, the icon, and the predicate all derive from one source.
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all
        case completed
        case skipped

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:        "All"
            case .completed:  "Completed"
            case .skipped:    "Skipped"
            }
        }

        var iconName: String {
            switch self {
            case .all:        "list.bullet"
            case .completed:  "checkmark.circle"
            case .skipped:    "xmark.circle"
            }
        }

        /// `nil` means "no status filter — keep everything". Returning
        /// optional lets the filter step short-circuit cleanly.
        var status: ChallengeStatus? {
            switch self {
            case .all:        nil
            case .completed:  .completed
            case .skipped:    .skipped
            }
        }
    }

    // MARK: Derived

    private var templateByID: [UUID: ChallengeTemplate] {
        Dictionary(uniqueKeysWithValues: allTemplates.map { ($0.id, $0) })
    }

    /// Everything historical (completed or skipped). Pending lives on
    /// Today, not History.
    private var historyChallenges: [DailyChallenge] {
        allDailyChallenges.filter { $0.status != .pending }
    }

    private var filteredChallenges: [DailyChallenge] {
        historyChallenges.filter { challenge in
            // Status check first — strictly cheapest predicate.
            if let required = statusFilter.status, challenge.status != required {
                return false
            }
            // Category check requires a template lookup, so we do it
            // second to avoid the dictionary hit on rows we'd discard
            // anyway.
            if let categoryFilter,
               templateByID[challenge.templateId]?.category != categoryFilter {
                return false
            }
            return true
        }
    }

    /// Filtered rows grouped by their normalized `date`, newest section
    /// first. Returned as an array of tuples (instead of a Dictionary)
    /// so the order survives — Dictionary iteration order is undefined.
    private var groupedByDate: [(date: Date, items: [DailyChallenge])] {
        let grouped = Dictionary(grouping: filteredChallenges, by: \.date)
        return grouped
            .map { (date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private var hasAnyFilter: Bool {
        categoryFilter != nil || statusFilter != .all
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !historyChallenges.isEmpty {
                    // Show the chip bar even when filters could hide
                    // every row — clearing the filter is part of the
                    // recovery path.
                    CategoryFilterBar(selection: $categoryFilter)
                }

                contentBody
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("History")
            .toolbar { statusFilterToolbar }
        }
    }

    // MARK: Content

    @ViewBuilder
    private var contentBody: some View {
        if historyChallenges.isEmpty {
            // No history at all — encouragement, not an error.
            PlaceholderScreen(
                title: "No history yet",
                iconName: "clock.arrow.circlepath",
                subtitle: "Complete or skip a challenge on Today to start building your history.",
                stepHint: nil
            )
        } else if filteredChallenges.isEmpty {
            filterEmptyState
        } else {
            historyList
        }
    }

    private var historyList: some View {
        List {
            ForEach(groupedByDate, id: \.date) { section in
                Section {
                    ForEach(section.items) { challenge in
                        if let template = templateByID[challenge.templateId] {
                            HistoryRow(challenge: challenge, template: template)
                        }
                    }
                } header: {
                    Text(sectionHeader(for: section.date))
                        .font(AppTypography.titleSmall)
                        .foregroundStyle(AppColors.textPrimary)
                        // `.textCase(nil)` overrides iOS's default
                        // section-header uppercasing, which would
                        // shout "TODAY" instead of saying "Today".
                        .textCase(nil)
                }
                // Per-section background sits behind the rows but
                // honors the brand background between sections.
                .listRowBackground(AppColors.surface)
            }
        }
        .listStyle(.plain)
        // Hide List's default white scroll background so the brand
        // background shows through — without this we'd get a stark
        // white block on dark mode.
        .scrollContentBackground(.hidden)
    }

    private var filterEmptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)

            VStack(spacing: AppSpacing.xs) {
                Text("No matches")
                    .font(AppTypography.titleMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("No history matches the current filter.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                categoryFilter = nil
                statusFilter = .all
            } label: {
                Label("Clear filter", systemImage: "xmark")
                    .font(AppTypography.bodyEmphasized)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(AppColors.primary)

            Spacer()
        }
        .padding(AppSpacing.xl)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var statusFilterToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                // `Picker` inside a Menu renders as a checklist —
                // SwiftUI auto-marks the selected option, which beats
                // hand-rolling our own checkmark logic.
                Picker("Status", selection: $statusFilter) {
                    ForEach(StatusFilter.allCases) { filter in
                        Label(filter.label, systemImage: filter.iconName).tag(filter)
                    }
                }
            } label: {
                // Filled icon when a non-default filter is active —
                // gives the user a passive cue that something is
                // narrowing the list, even if they navigated away and
                // came back.
                Image(systemName: statusFilter == .all
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill")
                    .foregroundStyle(statusFilter == .all
                        ? AppColors.textPrimary
                        : AppColors.primary)
            }
        }
    }

    // MARK: Section header copy

    /// Human-friendly date label for a History section.
    ///
    /// Branches on age:
    /// * Today / Yesterday (the most-frequent labels) get named.
    /// * 2–6 days ago: weekday name (Mon, Tue, ...) — short and unique
    ///   within the past week.
    /// * Older: full formatted date.
    private func sectionHeader(for date: Date) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let day = cal.startOfDay(for: date)

        let daysAgo = cal.dateComponents([.day], from: day, to: today).day ?? 0

        switch daysAgo {
        case 0:        return "Today"
        case 1:        return "Yesterday"
        case 2..<7:    return date.formatted(.dateTime.weekday(.wide))
        default:       return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [
            ChallengeTemplate.self,
            DailyChallenge.self,
            UserProgress.self,
            Badge.self
        ], inMemory: true)
}
