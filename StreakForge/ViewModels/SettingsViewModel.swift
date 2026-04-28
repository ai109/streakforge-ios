//
//  SettingsViewModel.swift
//  StreakForge
//
//  Owns the asynchronous permission state and orchestrates schedule
//  changes. The view stays sync-friendly; async work lives here.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

/// View-model for `SettingsView`.
///
/// Settings has more async surface than the other tabs (permission
/// requests, schedule writes) so a view-model earns its keep here even
/// though it's a relatively thin glue layer. Keeping `await` calls out
/// of view bodies makes the view easier to read and lets the view-model
/// be substituted in previews/tests.
@MainActor
@Observable
final class SettingsViewModel {

    var notificationService: NotificationService
    var progressService: ProgressService

    /// Mirrors the system's authorization status. Refreshed on every
    /// Settings appear via `bootstrap(...)` — the user can flip the
    /// permission in iOS Settings between visits, and we want to
    /// reflect that on next entry rather than caching forever.
    var permissionStatus: UNAuthorizationStatus = .notDetermined

    /// Same nil-then-build pattern as `TodayViewModel` — see that file
    /// for the MainActor-isolation rationale.
    init(
        notificationService: NotificationService? = nil,
        progressService: ProgressService? = nil
    ) {
        self.notificationService = notificationService ?? NotificationService()
        self.progressService = progressService ?? ProgressService()
    }

    // MARK: Bootstrap

    /// Pulled together from view `.task`:
    /// * Refreshes the permission status (catches grants made via iOS
    ///   Settings while the app was backgrounded).
    /// * Re-schedules the reminder if permission is granted, so the
    ///   pending notification always reflects the user's stored time
    ///   even after a reset, an OS upgrade, or a settings round-trip.
    ///
    /// Both halves are no-ops when nothing has changed, so calling this
    /// repeatedly is cheap.
    func bootstrap(reminderTime: Date?) async {
        await refreshPermissionStatus()
        if permissionStatus == .authorized, let time = reminderTime {
            await notificationService.scheduleDailyReminder(at: time)
        }
    }

    func refreshPermissionStatus() async {
        permissionStatus = await notificationService.authorizationStatus()
    }

    // MARK: Permission

    /// Triggers the system permission prompt, then schedules the
    /// reminder if the user granted. Surfaced as a single method (rather
    /// than two) so the view's button handler is one line.
    func requestPermissionAndSchedule(reminderTime: Date) async {
        _ = await notificationService.requestPermission()
        await refreshPermissionStatus()
        if permissionStatus == .authorized {
            await notificationService.scheduleDailyReminder(at: reminderTime)
        }
    }

    // MARK: Time updates

    /// Called when the DatePicker's selected time changes.
    /// Reschedules silently when permission is granted; no-ops otherwise
    /// (the new time is still saved to `UserProgress` by the binding —
    /// schedule runs the next time permission is granted).
    func updateReminderTime(_ time: Date) async {
        guard permissionStatus == .authorized else { return }
        await notificationService.scheduleDailyReminder(at: time)
    }

    // MARK: Reset

    /// Wipes user progress (delegates to `ProgressService`). Synchronous
    /// because all the work is local SwiftData mutations; no `await`
    /// boundary needed.
    func resetProgress(in context: ModelContext) {
        progressService.resetAll(in: context)
    }
}
