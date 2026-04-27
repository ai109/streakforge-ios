//
//  StreakForgeApp.swift
//  StreakForge
//
//  App entry point. Owns the `WindowGroup` and (from Step 2 onward) the
//  shared `ModelContainer` for SwiftData persistence.
//

import SwiftUI

/// App entry point.
///
/// The `ModelContainer` setup that Xcode's template installs has been
/// removed deliberately — there are no `@Model` types yet, and configuring
/// a container with an empty schema is wasted work. Step 2 reintroduces
/// `.modelContainer(...)` once the four real models exist.
@main
struct StreakForgeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
