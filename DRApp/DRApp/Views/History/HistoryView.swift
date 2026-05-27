import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]

    @State private var vm = HistoryViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Your reflections")
                    .font(AppTheme.Fonts.headingSerif)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.top, 24)

                if vm.weekGroups.isEmpty {
                    Text("Your reflections will appear here after you've logged some days.")
                        .font(AppTheme.Fonts.bodySerif)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineSpacing(5)
                        .padding(.top, 8)
                } else {
                    ForEach(vm.weekGroups) { group in
                        NavigationLink(value: AppDestination.weeklyMirror(weekStart: group.weekStart)) {
                            WeeklyCardView(group: group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Layout.horizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 40)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .appBackground()
        .task {
            await vm.load(entries: entries, reflections: reflections)
        }
        .onChange(of: entries.count) { _, _ in
            Task { await vm.load(entries: entries, reflections: reflections) }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(for: [DailyEntry.self, WeeklyReflection.self], inMemory: true)
            .environment(AppViewModel())
    }
}
