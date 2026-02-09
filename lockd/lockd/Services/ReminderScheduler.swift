import Foundation
import UserNotifications

final class ReminderScheduler {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Reminder authorization failed: \(error.localizedDescription)")
        }
    }

    func scheduleReminder(for task: PlannerTask) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.start)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder(taskID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [taskID.uuidString])
    }
}
