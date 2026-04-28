//
//  SeedDataService.swift
//  StreakForge
//
//  Inserts the canonical set of challenge templates and badge definitions
//  into the SwiftData store. Designed to be safe to run on every launch.
//

import Foundation
import SwiftData

/// Owns the app's static seed content (challenge templates, badge
/// definitions) and the first-launch insertion logic.
///
/// ## Idempotency
///
/// Every seed item has a hardcoded UUID. On each call, the seeder fetches
/// the IDs already present in the store and inserts only the items whose
/// IDs are missing. This means:
/// * First launch: inserts everything.
/// * Subsequent launches: zero inserts (cheap fetch + set-difference).
/// * App updates that add new templates/badges: only the new ones are
///   inserted, existing rows (including the user's `unlockedAt` on
///   badges) are untouched.
///
/// This is preferable to a one-shot `UserDefaults` "didSeed" flag because
/// that flag would prevent shipping new content in updates without manual
/// migration code.
struct SeedDataService {

    // MARK: Public entry point

    /// Inserts any missing canonical templates and badges into `context`.
    ///
    /// Call sites are expected to pass a context bound to the app's main
    /// `ModelContainer`. After insertion the context is saved so the seed
    /// is visible to subsequent `@Query` reads on the same container.
    func seedIfNeeded(in context: ModelContext) {
        seedTemplates(in: context)
        seedBadges(in: context)

        // We save explicitly (rather than relying on the implicit
        // auto-save) so that any view query that fires before the next
        // run-loop tick sees the seeded rows.
        do {
            try context.save()
        } catch {
            // Failing to persist the seed is recoverable in principle
            // (the next launch will retry), so we log rather than crash.
            // In a shipping app this would route to a real logger; here
            // a print is enough to surface during development.
            print("⚠️ SeedDataService failed to save: \(error)")
        }
    }

    // MARK: Templates

    private func seedTemplates(in context: ModelContext) {
        // Pull just the IDs of existing templates into a Set so the
        // membership check below is O(1) per candidate. Doing this once
        // up front is cheaper than a per-item fetch when the seed list
        // is small (30 items) but the store may not be.
        let existingIDs: Set<UUID> = {
            let descriptor = FetchDescriptor<ChallengeTemplate>()
            let rows = (try? context.fetch(descriptor)) ?? []
            return Set(rows.map(\.id))
        }()

        for definition in Self.templateDefinitions where !existingIDs.contains(definition.id) {
            // We construct a fresh `ChallengeTemplate` instance from the
            // definition rather than holding @Model instances as static
            // properties — SwiftData manages instance identity via the
            // context, and reusing instances across launches would be
            // ambiguous.
            context.insert(definition.makeModel())
        }
    }

    // MARK: Badges

    private func seedBadges(in context: ModelContext) {
        let existingIDs: Set<UUID> = {
            let descriptor = FetchDescriptor<Badge>()
            let rows = (try? context.fetch(descriptor)) ?? []
            return Set(rows.map(\.id))
        }()

        // Drive badge seeding from `BadgeKind.allCases` — that enum is the
        // single source of truth for badge identity, name, description, and
        // icon. Keeping the list here in lock-step with the evaluator was
        // exactly the kind of duplication that would silently rot.
        for kind in BadgeKind.allCases where !existingIDs.contains(kind.id) {
            context.insert(Badge(
                id: kind.id,
                name: kind.displayName,
                description: kind.description,
                iconName: kind.iconName
            ))
        }
    }
}

// MARK: - Definitions
//
// Definitions are kept as plain-data structs (not @Model instances) so the
// canonical content can be referenced from tests and previews without
// touching SwiftData. `makeModel()` materializes a fresh `@Model` instance
// inside the seeder when the row is missing from the store.

extension SeedDataService {

    /// Pure-data description of one challenge template.
    fileprivate struct TemplateDefinition {
        let id: UUID
        let title: String
        let description: String
        let category: ChallengeCategory
        let difficulty: ChallengeDifficulty
        let estMinutes: Int

        func makeModel() -> ChallengeTemplate {
            ChallengeTemplate(
                id: id,
                title: title,
                description: description,
                category: category,
                difficulty: difficulty,
                estMinutes: estMinutes
            )
        }
    }

    // (Badge metadata used to live here as a parallel `BadgeDefinition`
    // list. Step 4 moved that responsibility to `BadgeKind` so the seeder
    // and the evaluator can't drift apart.)

    // MARK: UUID literal helper
    //
    // Hardcoded UUID strings below are dereferenced via force-unwrap on
    // `UUID(uuidString:)`. This is genuinely safe — every literal is a
    // constant typed by hand, and a malformed literal would crash on the
    // very first launch (immediately surfaced in development). Re-generating
    // them at runtime would defeat the whole point of stable IDs.
    //
    // Naming scheme: `00000001-...-NNNNNNNNNNNN` for templates (last segment
    // = 1..30 in hex). The version nibble (`4` at position 13) and variant
    // nibble (`8` at position 17) make these spec-conformant UUIDs even
    // though they're hand-written. (Badge UUIDs use the `00000002-...`
    // prefix and live on `BadgeKind`.)

    fileprivate static let templateDefinitions: [TemplateDefinition] = [

        // MARK: Study (8) — book/coursework themed
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000001")!,
            title: "Read 5 pages of a book",
            description: "Pick up a physical or e-book and read at least five pages.",
            category: .study, difficulty: .easy, estMinutes: 10
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000002")!,
            title: "Watch a 5-min educational video",
            description: "Find a short video about something you want to understand better.",
            category: .study, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000003")!,
            title: "Look up a new word",
            description: "Find a word you don't know, read its definition, and use it in a sentence.",
            category: .study, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000004")!,
            title: "Practice a language for 15 min",
            description: "Open Duolingo, Anki, or any app and run through one full session.",
            category: .study, difficulty: .medium, estMinutes: 15
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000005")!,
            title: "Solve a logic or coding puzzle",
            description: "One Project Euler problem, one chess puzzle, one Sudoku — your pick.",
            category: .study, difficulty: .medium, estMinutes: 20
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000006")!,
            title: "Review notes from a recent class",
            description: "Open notes from the last week and re-read the key takeaways.",
            category: .study, difficulty: .medium, estMinutes: 15
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000007")!,
            title: "Complete one chapter of a course",
            description: "Pick a Coursera/Udemy/YouTube course and finish a full lesson.",
            category: .study, difficulty: .hard, estMinutes: 30
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000008")!,
            title: "Write a 200-word summary",
            description: "Pick something you learned today and write a 200-word recap of it.",
            category: .study, difficulty: .hard, estMinutes: 25
        ),

        // MARK: Social (7)
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000009")!,
            title: "Send a thoughtful message",
            description: "Tell a friend something you appreciate about them.",
            category: .social, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000000A")!,
            title: "Compliment someone today",
            description: "Pay one genuine compliment, in person or online.",
            category: .social, difficulty: .easy, estMinutes: 2
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000000B")!,
            title: "React to 3 friends' posts",
            description: "Like or comment on three posts from people you actually care about.",
            category: .social, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000000C")!,
            title: "Call a family member",
            description: "Phone or video-call someone in your family for at least 10 minutes.",
            category: .social, difficulty: .medium, estMinutes: 15
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000000D")!,
            title: "Reach out to an old friend",
            description: "Message someone you haven't spoken to in months and ask how they're doing.",
            category: .social, difficulty: .medium, estMinutes: 10
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000000E")!,
            title: "Plan a meetup this week",
            description: "Pick a friend, suggest a time and place, and lock it in.",
            category: .social, difficulty: .hard, estMinutes: 20
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000000F")!,
            title: "Have a 20-min real conversation",
            description: "No phone-scrolling — full attention on someone for at least 20 minutes.",
            category: .social, difficulty: .hard, estMinutes: 20
        ),

        // MARK: Health (8)
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000010")!,
            title: "Drink 2 glasses of water",
            description: "Pour two full glasses and drink them, ideally at different points in the day.",
            category: .health, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000011")!,
            title: "Take 5 deep breaths and stretch",
            description: "Stand up, stretch your arms and back, and take five slow deep breaths.",
            category: .health, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000012")!,
            title: "Stand up every hour today",
            description: "Set an hourly reminder and get on your feet for at least a minute each time.",
            category: .health, difficulty: .easy, estMinutes: 10
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000013")!,
            title: "Take a 15-minute walk outside",
            description: "Get out of the building, no podcast required — just walk.",
            category: .health, difficulty: .medium, estMinutes: 15
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000014")!,
            title: "Cook a balanced meal at home",
            description: "Protein + vegetables + carbs. Frozen veg counts.",
            category: .health, difficulty: .medium, estMinutes: 30
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000015")!,
            title: "Do a 10-min home workout",
            description: "Bodyweight exercises, yoga flow, or a YouTube workout — anything that gets your heart up.",
            category: .health, difficulty: .medium, estMinutes: 10
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000016")!,
            title: "Get 30 minutes of cardio",
            description: "Run, cycle, swim, or anything that keeps you moderately out of breath for half an hour.",
            category: .health, difficulty: .hard, estMinutes: 30
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000017")!,
            title: "Sleep at least 7 hours tonight",
            description: "Set a bedtime that gets you 7+ hours and actually stick to it.",
            category: .health, difficulty: .hard, estMinutes: 30
        ),

        // MARK: Mindfulness (7)
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000018")!,
            title: "List 3 things you're grateful for",
            description: "Write them down — paper or app, doesn't matter, but write them.",
            category: .mindfulness, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000019")!,
            title: "Spend 5 minutes phone-free",
            description: "Phone in another room. Just be where you are for five minutes.",
            category: .mindfulness, difficulty: .easy, estMinutes: 5
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000001A")!,
            title: "Notice and name 5 things",
            description: "Pause and identify five things you can see, hear, or feel right now.",
            category: .mindfulness, difficulty: .easy, estMinutes: 3
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000001B")!,
            title: "Meditate for 10 minutes",
            description: "Use Calm, Headspace, or just a timer — focus on your breath for ten minutes.",
            category: .mindfulness, difficulty: .medium, estMinutes: 10
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000001C")!,
            title: "Journal about your day",
            description: "Spend ten minutes writing about what happened today and how you felt about it.",
            category: .mindfulness, difficulty: .medium, estMinutes: 10
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000001D")!,
            title: "20 minutes outdoors, no devices",
            description: "Go outside, leave the phone behind, just be in the world for 20 minutes.",
            category: .mindfulness, difficulty: .hard, estMinutes: 20
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-4000-8000-00000000001E")!,
            title: "15-min body-scan meditation",
            description: "Lie down, slowly bring attention to each part of your body for fifteen minutes.",
            category: .mindfulness, difficulty: .hard, estMinutes: 15
        )
    ]

}
