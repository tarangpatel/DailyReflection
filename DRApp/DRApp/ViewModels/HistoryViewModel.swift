import Foundation
import SwiftData

// MARK: - WeekGroup

struct WeekGroup: Identifiable {
    let weekStart: Date
    let entries: [DailyEntry]
    var reflection: WeeklyReflection?

    var id: Date { weekStart }

    /// Label like "Week of Mar 10–16"
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "Week of \(formatter.string(from: weekStart))–\(formatter.string(from: end))"
    }

    /// Average mood score across entries in this week.
    var averageMood: Double {
        guard !entries.isEmpty else { return 0.5 }
        return entries.map(\.moodScore).reduce(0, +) / Double(entries.count)
    }
}

// MARK: - HistoryViewModel

@Observable
@MainActor
final class HistoryViewModel {

    var weekGroups: [WeekGroup] = []

    func load(entries: [DailyEntry], reflections: [WeeklyReflection]) async {
        let calendar = Calendar.current

        // Group entries by ISO week start (Monday)
        var groupedDict: [Date: [DailyEntry]] = [:]
        for entry in entries {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start
                ?? calendar.startOfDay(for: entry.date)
            groupedDict[weekStart, default: []].append(entry)
        }

        // Build WeekGroup array sorted newest first
        let groups = groupedDict.map { weekStart, weekEntries -> WeekGroup in
            let matchingReflection = reflections.first {
                calendar.startOfDay(for: $0.weekStartDate) == calendar.startOfDay(for: weekStart)
            }
            return WeekGroup(weekStart: weekStart, entries: weekEntries, reflection: matchingReflection)
        }
        .sorted { $0.weekStart > $1.weekStart }

        weekGroups = groups
    }
}
