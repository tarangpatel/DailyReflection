import SwiftUI
import SwiftData
import UserNotifications
import os

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
    var importSkippedCount: Int = 0
    var showImportSuccess: Bool = false

    // MARK: Export

    func exportCSV(entries: [DailyEntry]) async {
        isExporting = true
        defer { isExporting = false }
        do {
            exportURL = try await CSVService.shared.exportEntries(entries)
        } catch {
            AppLog.csv.error("exportCSV: \(String(describing: error), privacy: .public)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Import

    func importCSV(from url: URL, context: ModelContext, existingEntries: [DailyEntry]) async {
        isImporting = true
        defer { isImporting = false }

        do {
            let result = try await CSVService.shared.importEntries(from: url)
            let calendar = Calendar.current

            let existingDates = Set(existingEntries.map {
                calendar.startOfDay(for: $0.date)
            })

            var insertedCount = 0
            var duplicateCount = 0
            for record in result.records {
                let day = calendar.startOfDay(for: record.date)
                guard !existingDates.contains(day) else {
                    duplicateCount += 1
                    continue
                }

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
            if duplicateCount > 0 {
                AppLog.csv.debug("importCSV: skipped \(duplicateCount, privacy: .public) rows already present on-device")
            }

            guard context.saveLogging("importCSV") else {
                errorMessage = "Your file was read, but the imported entries couldn't be saved. Please try again."
                return
            }

            importSuccessCount = insertedCount
            importSkippedCount = result.skippedRowCount + duplicateCount
            showImportSuccess = true
        } catch {
            AppLog.csv.error("importCSV: \(String(describing: error), privacy: .public)")
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

        do {
            try await scheduleReminder()
            notificationsEnabled = true
            UserDefaults.standard.set(true, forKey: Self.enabledKey)
        } catch {
            AppLog.notifications.error("setNotificationsEnabled: scheduleReminder failed: \(String(describing: error), privacy: .public)")
            notificationsEnabled = false
            UserDefaults.standard.set(false, forKey: Self.enabledKey)
            errorMessage = "Your daily reminder couldn't be scheduled. Please try again."
        }
    }

    func updateReminderTime(_ date: Date) async {
        reminderTime = date
        let calendar = Calendar.current
        UserDefaults.standard.set(calendar.component(.hour, from: date), forKey: Self.reminderHourKey)
        UserDefaults.standard.set(calendar.component(.minute, from: date), forKey: Self.reminderMinuteKey)
        guard notificationsEnabled else { return }
        do {
            try await scheduleReminder()
        } catch {
            AppLog.notifications.error("updateReminderTime: scheduleReminder failed: \(String(describing: error), privacy: .public)")
            notificationsEnabled = false
            UserDefaults.standard.set(false, forKey: Self.enabledKey)
            errorMessage = "Your daily reminder couldn't be rescheduled. Please try again."
        }
    }

    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        AppLog.notifications.debug("requestNotificationPermission: current status \(String(describing: settings.authorizationStatus), privacy: .public)")
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .denied:
            return false
        default:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                AppLog.notifications.error("requestNotificationPermission: requestAuthorization failed: \(String(describing: error), privacy: .public)")
                return false
            }
        }
    }

    private func scheduleReminder() async throws {
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
        try await center.add(request)
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
