import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedule a reminder N days before a date.
    func scheduleInsuranceReminder(plate: String, expiryDate: Date, daysBefore: Int = 30) async {
        let granted = await requestPermission()
        guard granted else { return }

        let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiryDate) ?? expiryDate

        // Don't schedule if trigger date is in the past
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Insurance Expiring Soon"
        content.body = "The insurance for \(plate) expires in \(daysBefore) days. Renew it to avoid penalties."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "insurance_\(plate.replacingOccurrences(of: " ", with: ""))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Schedule a fitness certificate expiry reminder.
    func scheduleFitnessReminder(plate: String, expiryDate: Date, daysBefore: Int = 90) async {
        let granted = await requestPermission()
        guard granted else { return }

        let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiryDate) ?? expiryDate
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Fitness Certificate Expiring"
        content.body = "The fitness certificate for \(plate) expires in \(daysBefore) days."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "fitness_\(plate.replacingOccurrences(of: " ", with: ""))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Cancel all reminders for a plate.
    func cancelReminders(for plate: String) {
        let cleaned = plate.replacingOccurrences(of: " ", with: "")
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["insurance_\(cleaned)", "fitness_\(cleaned)"]
        )
    }
}
