//
//  RootTabView.swift
//  StreakForge
//
//  The 5-tab shell that hosts every top-level screen.
//

import SwiftUI

/// Top-level tab navigation for the app.
///
/// We use the modern `Tab(_:systemImage:)` API (iOS 18+) rather than the
/// classic `.tabItem` modifier — it's strictly more declarative and lets
/// us add features like `Tab.role(.search)` later without a refactor.
///
/// The active tab tint is the brand orange. Tab order follows the user's
/// daily journey: Today (do) → Stats (reflect) → Badges (achieve) →
/// History (look back) → Settings (configure). Settings sits last, like
/// in most iOS apps, so the user's finger doesn't accidentally tap it
/// while reaching for Today.
struct RootTabView: View {

    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max.fill") {
                TodayView()
            }
            Tab("Stats", systemImage: "chart.bar.xaxis") {
                StatsView()
            }
            Tab("Badges", systemImage: "rosette") {
                BadgesView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        // Tinting the TabView affects the selected-tab color and the
        // accent inside each child view (unless the child overrides it).
        // Setting it once here keeps the brand consistent without every
        // screen having to repeat `.tint(AppColors.primary)`.
        .tint(AppColors.primary)
    }
}

#Preview {
    RootTabView()
}
