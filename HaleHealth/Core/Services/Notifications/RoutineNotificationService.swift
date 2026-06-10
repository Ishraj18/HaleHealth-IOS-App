import Foundation
import OSLog
import UserNotifications

/// Schedules daily local reminders for routine blocks. Push (APNs) remains a
/// Phase 2 concern; this is purely local.
@MainActor
final class RoutineNotificationService {
    static let shared = RoutineNotificationService()
    private let center = UNUserNotificationCenter.current()
    private static let idPrefix = "routine-block-"

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            Log.app.error("Notification auth failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Replaces all block reminders with the given routine's schedule (daily repeat).
    func schedule(for routine: DailyRoutine) async {
        await cancelAll()
        for block in routine.blocks where block.kind != .sleep {
            let content = UNMutableNotificationContent()
            content.title = block.title
            content.body = block.detail
            content.sound = .default

            var date = DateComponents()
            date.hour = block.startMinutes / 60
            date.minute = block.startMinutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

            let request = UNNotificationRequest(
                identifier: Self.idPrefix + block.id, content: content, trigger: trigger
            )
            do { try await center.add(request) }
            catch { Log.app.error("Reminder schedule failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
    }
}
