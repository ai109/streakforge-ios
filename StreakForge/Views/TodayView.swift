//
//  TodayView.swift
//  StreakForge
//
//  Step 5: navigation skeleton only. Step 6 fills in the real screen
//  (challenge cards, complete/skip/swap, XP-gain animation).
//

import SwiftUI

/// The "Today" tab — the user's daily set of three challenges with
/// complete / skip / swap actions, plus the running XP and streak.
///
/// Currently a `NavigationStack` wrapping a themed placeholder. The stack
/// is in place so Step 6's drill-downs (challenge detail sheets) slot in
/// without restructuring.
struct TodayView: View {
    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                title: "Today",
                iconName: "sun.max.fill",
                subtitle: "Your three challenges for today, plus your running XP and streak.",
                stepHint: "Coming in Step 6"
            )
            .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
