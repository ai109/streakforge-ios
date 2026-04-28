//
//  NotificationService.swift
//  StreakForge
//
//  Thin wrapper around `UNUserNotificationCenter` for the daily reminder.
//

import Foundation
import UserNotifications

/// Owns the permission flow and the single repeating "daily challenges
/// are ready" notification.
///
/// Wrapping the framework — even thinly — buys two things:
/// * The view-model can talk to a small, named API instead of importing
///   `UserNotifications` everywhere.
/// * Tests in Step 12 can substitute a fake by passing a different
///   instance into `SettingsViewModel`.
struct NotificationService {

    /// Stable identifier for the daily reminder so we can replace it
    /// (rather than stack duplicates) on every reschedule.
    static let dailyReminderID = "com.angelivanov.StreakForge.dailyReminder"

    /// Asks the user for permission to deliver alerts and sounds. Should
    /// be invoked from a deliberate user action — never on app launch —
    /// per the permission flow agreed at project kickoff.
    ///
    /// - Returns: `true` if granted, `false` if the user denied or the
    ///   call errored. We collapse those two outcomes because the UI's
    ///   downstream behavior is the same either way: refresh the
    ///   `authorizationStatus()` and render whatever it now is.
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Reads the current authorization status without prompting. Used to
    /// drive the Settings row state on every appear.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Schedules the daily reminder at `time`'s hour/minute, every day.
    ///
    /// The date portion of `time` is ignored — only the hour and minute
    /// components matter — because the trigger is a calendar match that
    /// repeats indefinitely. We cancel any existing pending request with
    /// the same ID first so back-to-back changes can't stack two
    /// notifications.
    func scheduleDailyReminder(at time: Date) async {
        let center = UNUserNotificationCenter.current()
        // Cancel-then-add is the documented idempotent pattern for
        // reschedule. It's safe even when no request exists yet.
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderID])

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "StreakForge"
        content.body  = "Your daily challenges are ready — keep your streak alive."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Self.dailyReminderID,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // The most common failure here is missing permission, which
            // the UI surfaces separately via `authorizationStatus()`.
            // Logging is enough — re-trying or alerting would be noise.
            print("⚠️ NotificationService failed to schedule: \(error)")
        }
    }

    /// Removes the pending daily reminder. Useful for testing and for a
    /// future "pause notifications" toggle if we ever add one.
    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderID])
    }
}
