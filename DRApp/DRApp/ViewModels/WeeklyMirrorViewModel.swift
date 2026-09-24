import SwiftUI
import SwiftData
import os

@Observable
@MainActor
final class WeeklyMirrorViewModel {

    var reflection: WeeklyReflection? = nil
    var isGenerating: Bool = false

    // MARK: Load or Generate

    func loadOrGenerate(
        for weekStart: Date,
        allEntries: [DailyEntry],
        allReflections: [WeeklyReflection],
        context: ModelContext
    ) async {
        // Check for existing persisted reflection
        let weekStartDay = Calendar.current.startOfDay(for: weekStart)
        if let existing = allReflections.first(where: {
            Calendar.current.startOfDay(for: $0.weekStartDate) == weekStartDay
        }) {
            reflection = existing
            return
        }

        // Filter entries belonging to this week
        guard let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDay) else {
            AppLog.app.error("loadOrGenerate: couldn't compute week end for \(weekStartDay, privacy: .public)")
            return
        }
        let weekEntries = allEntries.filter {
            $0.date >= weekStartDay && $0.date < weekEnd
        }

        guard !weekEntries.isEmpty else { return }

        isGenerating = true
        defer { isGenerating = false }

        let narrative = await ReflectionNarrativeService.shared.generateNarrative(
            for: weekEntries,
            weekStartDate: weekStartDay
        )

        let avgMood   = weekEntries.map(\.moodScore).reduce(0, +) / Double(weekEntries.count)
        let avgEnergy = weekEntries.map(\.energyLevel).reduce(0, +) / Double(weekEntries.count)

        let newReflection = WeeklyReflection(
            weekStartDate: weekStartDay,
            summaryText: narrative,
            averageMood: avgMood,
            averageEnergy: avgEnergy
        )
        context.insert(newReflection)
        context.saveLogging("loadOrGenerate")
        reflection = newReflection
    }

    // MARK: Feedback

    func submitFeedback(_ rating: String, context: ModelContext) async {
        reflection?.accuracyRating = rating
        context.saveLogging("submitFeedback")
    }
}
