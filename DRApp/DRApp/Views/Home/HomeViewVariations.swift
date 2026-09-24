import SwiftUI
import SwiftData

#if DEBUG

// MARK: - Preview Data Helpers

private func isoWeekStart(for date: Date) -> Date {
    Calendar(identifier: .iso8601).dateInterval(of: .weekOfYear, for: date)?.start ?? date
}

private func daysAgo(_ n: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -n, to: Date())!
}

private func entry(daysAgo n: Int, mood: Double, energy: Double, oneWord: String = "", whatMattered: String = "") -> DailyEntry {
    DailyEntry(date: daysAgo(n), moodScore: mood, energyLevel: energy, oneWord: oneWord, whatMattered: whatMattered)
}

private func reflection(weeksAgo n: Int, summary: String, averageMood: Double, averageEnergy: Double, accuracyRating: String? = nil) -> WeeklyReflection {
    WeeklyReflection(
        weekStartDate: isoWeekStart(for: daysAgo(n * 7)),
        summaryText: summary,
        accuracyRating: accuracyRating,
        averageMood: averageMood,
        averageEnergy: averageEnergy
    )
}

private func container(entries: [DailyEntry], reflections: [WeeklyReflection]) -> ModelContainer {
    let schema = Schema([DailyEntry.self, WeeklyReflection.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    entries.forEach { container.mainContext.insert($0) }
    reflections.forEach { container.mainContext.insert($0) }
    return container
}

// MARK: - 1. New User — nothing logged yet

#Preview("1. New User — Empty State") {
    NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: [], reflections: []))
    .environment(AppViewModel())
}

// MARK: - 2. Early days — some reflections within the first week, no weekly summary yet

#Preview("2. Early Days — Partial Week") {
    let entries = [
        entry(daysAgo: 0, mood: 0.6, energy: 0.5, oneWord: "hopeful"),
        entry(daysAgo: 1, mood: 0.4, energy: 0.4, oneWord: "tired"),
        entry(daysAgo: 2, mood: 0.7, energy: 0.6, oneWord: "curious")
    ]
    return NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: entries, reflections: []))
    .environment(AppViewModel())
}

// MARK: - 3. One full week logged — first weekly reflection appears

#Preview("3. One Week Complete") {
    let entries = (1...7).map { day in
        entry(daysAgo: day, mood: Double.random(in: 0.35...0.75), energy: Double.random(in: 0.35...0.75))
    }
    let reflections = [
        reflection(
            weeksAgo: 1,
            summary: "This week you moved between steadiness and quiet fatigue. Mornings felt lighter than evenings, and you kept showing up even on the harder days.",
            averageMood: 0.58,
            averageEnergy: 0.5
        )
    ]
    return NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: entries, reflections: reflections))
    .environment(AppViewModel())
}

// MARK: - 4. One month in — several weekly reflections accumulated

#Preview("4. One Month In") {
    let entries = (1...28).map { day in
        entry(daysAgo: day, mood: Double.random(in: 0.3...0.85), energy: Double.random(in: 0.3...0.85))
    }
    let reflections = [
        reflection(weeksAgo: 1, summary: "A steadier week — your energy climbed midweek and stayed there through the weekend.", averageMood: 0.64, averageEnergy: 0.6, accuracyRating: "yes"),
        reflection(weeksAgo: 2, summary: "Mood dipped early on but recovered by Thursday. You leaned on rest more than usual.", averageMood: 0.5, averageEnergy: 0.45, accuracyRating: "somewhat"),
        reflection(weeksAgo: 3, summary: "One of your brighter weeks — consistent energy and a few standout good days.", averageMood: 0.7, averageEnergy: 0.68, accuracyRating: "yes"),
        reflection(weeksAgo: 4, summary: "A slower start to the month, with mood and energy tracking closely together.", averageMood: 0.55, averageEnergy: 0.52)
    ]
    return NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: entries, reflections: reflections))
    .environment(AppViewModel())
}

// MARK: - 5. Returning after a break — the "last week" card is actually weeks old

#Preview("5. Returning After A Break") {
    // No recent entries; the only reflection on file is stale. HomeView has no
    // staleness check, so this card silently reads as current.
    let entries = (25...31).map { day in
        entry(daysAgo: day, mood: Double.random(in: 0.3...0.7), energy: Double.random(in: 0.3...0.7))
    }
    let reflections = [
        reflection(weeksAgo: 4, summary: "Before your break, you were logging consistently with mild energy dips midweek.", averageMood: 0.52, averageEnergy: 0.48)
    ]
    return NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: entries, reflections: reflections))
    .environment(AppViewModel())
}

// MARK: - 6. Long reflection summary — tests the 3-line clamp

#Preview("6. Long Summary Text") {
    let entries = (1...7).map { day in entry(daysAgo: day, mood: 0.6, energy: 0.55) }
    let reflections = [
        reflection(
            weeksAgo: 1,
            summary: "This was a week of contrasts: quiet, grounded mornings gave way to restless evenings more often than not, and you noticed yourself reaching for distraction on the days when energy dipped. By the weekend, though, something settled — a walk, a long conversation, a night of real sleep — and you ended the week steadier than you started it, even if you couldn't quite name why.",
            averageMood: 0.55,
            averageEnergy: 0.5
        )
    ]
    return NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: entries, reflections: reflections))
    .environment(AppViewModel())
}

// MARK: - 7. Dark mode

#Preview("7. Dark Mode — One Month In") {
    let entries = (1...28).map { day in
        entry(daysAgo: day, mood: Double.random(in: 0.3...0.85), energy: Double.random(in: 0.3...0.85))
    }
    let reflections = [
        reflection(weeksAgo: 1, summary: "A steadier week — your energy climbed midweek and stayed there through the weekend.", averageMood: 0.64, averageEnergy: 0.6)
    ]
    return NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: entries, reflections: reflections))
    .environment(AppViewModel())
    .preferredColorScheme(.dark)
}

// MARK: - 8. Accessibility — large Dynamic Type size

#Preview("8. Accessibility — Large Dynamic Type") {
    let entries = (1...7).map { day in entry(daysAgo: day, mood: 0.6, energy: 0.55) }
    let reflections = [
        reflection(weeksAgo: 1, summary: "This week you moved between steadiness and quiet fatigue.", averageMood: 0.58, averageEnergy: 0.5)
    ]
    return NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: entries, reflections: reflections))
    .environment(AppViewModel())
    .environment(\.dynamicTypeSize, .accessibility3)
}

// MARK: - 9. Compact device size

#Preview("9. Compact Device — iPhone SE", traits: .fixedLayout(width: 375, height: 667)) {
    NavigationStack {
        HomeView()
    }
    .modelContainer(container(entries: [], reflections: []))
    .environment(AppViewModel())
}

#endif
