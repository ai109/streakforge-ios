//
//  SettingsView.swift
//  StreakForge
//
//  The Settings tab — daily reminder time + permission, reset progress,
//  and an About section.
//

import SwiftUI
import SwiftData
import UserNotifications

/// The Settings tab.
///
/// A standard iOS `Form`. We deliberately don't reinvent the settings
/// look — the conventional sectioned-list aesthetic is what users expect
/// here, and going custom would feel less polished, not more.
struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var allProgress: [UserProgress]

    @State private var viewModel = SettingsViewModel()
    @State private var showingResetConfirm = false

    private var progress: UserProgress? { allProgress.first }

    /// Fallback time if `UserProgress` doesn't exist yet (shouldn't
    /// happen — TodayViewModel.bootstrap creates the row — but the
    /// DatePicker needs a non-nil binding regardless).
    private static let fallbackTime: Date = {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? .now
    }()

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                progressSection
                aboutSection
            }
            // Strip Form's default grouped-list background so the brand
            // background can show through. Without this we'd get the
            // default light-gray on light mode and a flat black on dark.
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .task {
                await viewModel.bootstrap(reminderTime: progress?.notificationTime)
            }
            .alert("Reset progress?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) {
                    viewModel.resetProgress(in: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all your daily challenges, resets your XP and streak, and re-locks every badge. Your reminder time stays the same. This can't be undone.")
            }
        }
    }

    // MARK: Notification section

    private var notificationSection: some View {
        Section {
            DatePicker(
                "Reminder time",
                selection: reminderTimeBinding,
                displayedComponents: .hourAndMinute
            )

            permissionRow
        } header: {
            Text("Daily reminder")
        } footer: {
            Text("StreakForge sends one notification at this time each day to remind you about your challenges.")
        }
    }

    /// Two-way binding into `UserProgress.notificationTime` that also
    /// kicks off a reschedule on every change. Built inline (rather
    /// than as a stored property) because it captures `progress`
    /// and `viewModel`, both of which can change between renders.
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { progress?.notificationTime ?? Self.fallbackTime },
            set: { newValue in
                progress?.notificationTime = newValue
                // SwiftData autosaves on context changes, but calling
                // save explicitly here removes any race between the
                // mutation and the upcoming reschedule that depends on
                // it being persisted.
                try? modelContext.save()
                Task { await viewModel.updateReminderTime(newValue) }
            }
        )
    }

    @ViewBuilder
    private var permissionRow: some View {
        switch viewModel.permissionStatus {
        case .notDetermined:
            // First-visit CTA. Tapping triggers the OS prompt.
            Button {
                Task {
                    await viewModel.requestPermissionAndSchedule(
                        reminderTime: progress?.notificationTime ?? Self.fallbackTime
                    )
                }
            } label: {
                Label("Enable notifications", systemImage: "bell.badge")
                    .foregroundStyle(AppColors.primary)
            }

        case .authorized, .provisional, .ephemeral:
            HStack {
                Label("Notifications enabled", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.success)
                Spacer()
            }

        case .denied:
            // Permission was denied — we can't re-prompt, so we point
            // the user at iOS Settings, which is the only place the
            // toggle can be flipped back from here.
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Notifications disabled", systemImage: "bell.slash.fill")
                    .foregroundStyle(AppColors.danger)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open iOS Settings")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.primary)
                }
            }

        @unknown default:
            // New status case in a future iOS — silently no-op so we
            // don't crash. The user's reminder time is still saved to
            // UserProgress regardless.
            EmptyView()
        }
    }

    // MARK: Progress section

    private var progressSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label("Reset progress", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("Progress")
        } footer: {
            Text("Resets XP, streak, and badges. Templates and your reminder time are kept.")
        }
    }

    // MARK: About section

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Build", value: appBuild)
            LabeledContent("Made by", value: "Angel Ivanov")
        } header: {
            Text("About")
        } footer: {
            Text("StreakForge — daily micro-challenges for building habits, one day at a time.")
        }
    }

    /// Marketing version (CFBundleShortVersionString) — falls back to
    /// "1.0" so the row never reads empty during development before the
    /// Info.plist is finalized.
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// Build number (CFBundleVersion). Kept in a separate row from the
    /// marketing version so QA/grading can identify the exact build.
    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            ChallengeTemplate.self,
            DailyChallenge.self,
            UserProgress.self,
            Badge.self
        ], inMemory: true)
}
