//
//  StreakForgeApp.swift
//  StreakForge
//
//  App entry point. Owns the `WindowGroup` and the shared `ModelContainer`
//  for SwiftData persistence.
//

import SwiftUI
import SwiftData

/// App entry point.
///
/// The shared `ModelContainer` is built lazily once at launch and injected
/// into the SwiftUI environment via `.modelContainer(_:)`, which makes it
/// available to every view through `@Environment(\.modelContext)` and to
/// `@Query` property wrappers.
@main
struct StreakForgeApp: App {

    /// The single SwiftData container that owns all four `@Model` types.
    ///
    /// Built as a lazy stored property (computed inside the closure) so it
    /// runs exactly once and any error is surfaced immediately at launch
    /// rather than on first use deep inside a view body.
    private let modelContainer: ModelContainer = {
        // Listing the model types here is what makes them part of the
        // schema — adding a new `@Model` later means adding it to this
        // array and (usually) running a lightweight migration.
        let schema = Schema([
            ChallengeTemplate.self,
            DailyChallenge.self,
            UserProgress.self,
            Badge.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            // Persist to disk — we want streaks/XP to survive app relaunches.
            // Tests will pass `isStoredInMemoryOnly: true` via their own
            // container, so we don't need a build-flag branch here.
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])

            // Seed canonical content (challenge templates + badges) before
            // any view's `@Query` fires. Doing this inline in the container
            // factory — rather than from `RootView.task` — guarantees the
            // first frame already sees the seeded rows, avoiding a
            // flash-of-empty-state on first launch. The seeder is
            // idempotent (id-keyed), so it's safe to run on every launch.
            SeedDataService().seedIfNeeded(in: ModelContext(container))

            return container
        } catch {
            // Persistence is non-optional for this app — a daily-challenge
            // tracker that can't remember yesterday is functionally broken.
            // A clear crash with the underlying error is the most useful
            // failure mode here; there is no graceful degradation worth
            // shipping.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
