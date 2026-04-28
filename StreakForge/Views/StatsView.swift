//
//  StatsView.swift
//  StreakForge
//
//  Step 5: navigation skeleton only. Step 7 wires Apple `Charts` and
//  weekly/monthly toggles.
//

import SwiftUI

/// The "Stats" tab — completion chart (weekly + monthly), per-category
/// breakdown, and overall completion rate.
struct StatsView: View {
    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                title: "Stats",
                iconName: "chart.bar.xaxis",
                subtitle: "Weekly and monthly completion charts and a breakdown by category.",
                stepHint: "Coming in Step 7"
            )
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    StatsView()
}
