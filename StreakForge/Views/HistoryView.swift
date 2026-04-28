//
//  HistoryView.swift
//  StreakForge
//
//  Step 5: navigation skeleton only. Step 9 wires the filterable list and
//  empty state.
//

import SwiftUI

/// The "History" tab — every completed and skipped challenge, filterable
/// by category and status.
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                title: "History",
                iconName: "clock.arrow.circlepath",
                subtitle: "Every challenge you've completed or skipped, filterable by category and status.",
                stepHint: "Coming in Step 9"
            )
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
