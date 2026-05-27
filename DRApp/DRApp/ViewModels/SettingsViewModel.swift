import SwiftUI
import SwiftData
import UserNotifications

@Observable
@MainActor
final class SettingsViewModel {

    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
            if newValue { requestNotificationPermission() }
        }
    }

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
                    whatMattered: record.whatMattered
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

    private func requestNotificationPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
    }
}
