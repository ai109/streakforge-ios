//
//  SettingsView.swift
//  StreakForge
//
//  Step 5: navigation skeleton only. Step 10 wires the reminder time
//  picker, notification permission flow, reset-progress confirmation,
//  and the about/credits section.
//

import SwiftUI

/// The "Settings" tab — daily reminder time, notification permission,
/// reset progress, and about.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                title: "Settings",
                iconName: "gearshape.fill",
                subtitle: "Set your daily reminder time, reset progress, and view app info.",
                stepHint: "Coming in Step 10"
            )
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
