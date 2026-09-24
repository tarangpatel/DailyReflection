import SwiftUI
import SwiftData
import UserNotifications

@Observable
@MainActor
final class SettingsViewModel {

    private static let reminderIdentifier = "dailyReflectionReminder"
    private static let enabledKey = "notificationsEnabled"
    private static let reminderHourKey = "reminderHour"
    private static let reminderMinuteKey = "reminderMinute"

    var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: SettingsViewModel.enabledKey)
    var reminderTime: Date = SettingsViewModel.loadReminderTime()
    var showPermissionDeniedAlert: Bool = false

    var exportURL: URL? = nil
    var isExporting: Bool = false
    var isImporting: Bool = false
    var showImportFilePicker: Bool = false
    var errorMessage: String? = nil
    var importSuccessCount: Int = 0
    var showImportSuccess: Bool = false

    // MARK: Export

    func exportCSV(entries: [DailyEntry]) async {
        isExporting = true
        defer { isExporting = false }
        do {
            exportURL = try await CSVService.shared.exportEntries(entries)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Import

    func importCSV(from url: URL, context: ModelContext, existingEntries: [DailyEntry]) async {
        isImporting = true
        defer { isImporting = false }

        do {
            let records = try await CSVService.shared.importEntries(from: url)
            let calendar = Calendar.current

            let existingDates = Set(existingEntries.map {
                calendar.startOfDay(for: $0.date)
            })

            var insertedCount = 0
            for record in records {
                let day = calendar.startOfDay(for: record.date)
                guard !existingDates.contains(day) else { continue }

                let entry = DailyEntry(
                    date: record.date,
                    moodScore: record.moodScore,
                    energyLevel: record.energyLevel,
                    oneWord: record.oneWord,
                    whatMattered: record.whatMattered,
                    voiceNoteTranscript: record.voiceNoteTranscript
                )
                context.insert(entry)
                insertedCount += 1
            }

            try? context.save()
            importSuccessCount = insertedCount
            showImportSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Notifications

    /// Toggles the daily reminder. Requests authorization on enable; if denied,
    /// reverts the toggle and surfaces an alert pointing to Settings.
    func setNotificationsEnabled(_ enabled: Bool) async {
        guard enabled else {
            notificationsEnabled = false
            UserDefaults.standard.set(false, forKey: Self.enabledKey)
            cancelReminder()
            return
        }

        let granted = await requestNotificationPermission()
        guard granted else {
            notificationsEnabled = false
            UserDefaults.standard.set(false, forKey: Self.enabledKey)
            showPermissionDeniedAlert = true
            return
        }

        notificationsEnabled = true
        UserDefaults.standard.set(true, forKey: Self.enabledKey)
        scheduleReminder()
    }

    func updateReminderTime(_ date: Date) {
        reminderTime = date
        let calendar = Calendar.current
        UserDefaults.standard.set(calendar.component(.hour, from: date), forKey: Self.reminderHourKey)
        UserDefaults.standard.set(calendar.component(.minute, from: date), forKey: Self.reminderMinuteKey)
        if notificationsEnabled {
            scheduleReminder()
        }
    }

    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Daily Reflection"
        content.body = "Take a moment to reflect on your day."
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: reminderTime)
        dateComponents.minute = calendar.component(.minute, from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: Self.reminderIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
    }

    private static func loadReminderTime() -> Date {
        let defaults = UserDefaults.standard
        let hour = defaults.object(forKey: reminderHourKey) as? Int ?? 20
        let minute = defaults.object(forKey: reminderMinuteKey) as? Int ?? 0
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
