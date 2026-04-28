//
//  RootView.swift
//  StreakForge
//
//  The single composition point installed by `StreakForgeApp`.
//

import SwiftUI

/// The view installed at the top of the SwiftUI hierarchy.
///
/// Currently this is just a passthrough to `RootTabView`. It exists as a
/// dedicated layer (rather than `StreakForgeApp` calling `RootTabView`
/// directly) so that future additions — splash screen, first-run
/// onboarding, "what's new" sheets — have one obvious place to live
/// without rewriting the app entry point.
struct RootView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    RootView()
}
