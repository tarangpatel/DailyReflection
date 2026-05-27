import SwiftUI
import SwiftData

struct WeeklyMirrorView: View {
    let weekStart: Date

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @Query(sort: \WeeklyReflection.weekStartDate) private var allReflections: [WeeklyReflection]

    @State private var vm = WeeklyMirrorViewModel()

    private var weekLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "Week of \(f.string(from: weekStart))–\(f.string(from: end))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(weekLabel)
                        .font(AppTheme.Fonts.captionSans)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .kerning(0.8)

                    Text("Your week, reflected")
                        .font(AppTheme.Fonts.headingSerif)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                .padding(.top, 24)

                Divider().background(AppTheme.Colors.divider)

                // Narrative body
                if vm.isGenerating {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(AppTheme.Colors.textSecondary)
                            .padding(.vertical, 40)
                        Spacer()
                    }
                } else if let reflection = vm.reflection {
                    Text(reflection.summaryText)
                        .font(AppTheme.Fonts.bodySerif)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineSpacing(8)

                    Divider().background(AppTheme.Colors.divider)

                    // Accuracy feedback
                    accuracySection(reflection: reflection)
                } else {
                    Text("No entries were recorded for this week.")
                        .font(AppTheme.Fonts.bodySerif)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineSpacing(6)
                }
            }
            .padding(.horizontal, AppTheme.Layout.horizontalPadding)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
        .task {
            await vm.loadOrGenerate(
                for: weekStart,
                allEntries: allEntries,
                allReflections: allReflections,
                context: modelContext
            )
        }
    }

    @ViewBuilder
    private func accuracySection(reflection: WeeklyReflection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Did this feel accurate?")
                .font(AppTheme.Fonts.labelSans)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack(spacing: 10) {
                ForEach(["Yes", "Somewhat", "No"], id: \.self) { option in
                    let isSelected = reflection.accuracyRating == option.lowercased()
                    Button {
                        Task {
                            await vm.submitFeedback(option.lowercased(), context: modelContext)
                        }
                    } label: {
                        Text(option)
                            .font(AppTheme.Fonts.labelSans)
                            .foregroundStyle(
                                isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary
                            )
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isSelected ? AppTheme.Colors.surface : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(
                                                AppTheme.Colors.divider,
                                                lineWidth: isSelected ? 0 : 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(AppTheme.Animation.slowFade, value: isSelected)
                }
                Spacer()
            }
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack {
        WeeklyMirrorView(weekStart: Date())
            .modelContainer(for: [DailyEntry.self, WeeklyReflection.self], inMemory: true)
    }
}
