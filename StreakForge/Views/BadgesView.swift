//
//  BadgesView.swift
//  StreakForge
//
//  Step 5: navigation skeleton only. Step 8 wires the badge grid and the
//  unlock animation.
//

import SwiftUI

/// The "Badges" tab — grid of all 10 badges (locked + unlocked), each
/// tappable to reveal its unlock criterion and earned date.
struct BadgesView: View {
    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                title: "Badges",
                iconName: "rosette",
                subtitle: "Your unlocked achievements and the ones still ahead.",
                stepHint: "Coming in Step 8"
            )
            .navigationTitle("Badges")
        }
    }
}

#Preview {
    BadgesView()
}
