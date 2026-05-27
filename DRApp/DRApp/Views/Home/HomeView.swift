import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:     return "Good evening"
        }
    }

    private var lastWeekReflection: WeeklyReflection? {
        reflections.first
    }

    private var lastWeekStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Previous ISO week start
        return calendar.date(byAdding: .weekOfYear, value: -1, to: isoWeekStart(for: today))!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
                // Greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(AppTheme.Fonts.uiSans(15))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text("Ready to reflect?")
                        .font(AppTheme.Fonts.titleSerif)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                .padding(.top, 32)

                // Primary action
                NavigationLink(value: AppDestination.dailyEntry) {
                    HStack {
                        Text("Start today's entry")
                            .font(AppTheme.Fonts.buttonSans)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                }
                .buttonStyle(.plain)

                Divider()
                    .background(AppTheme.Colors.divider)

                // Last week reflection card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last week")
                        .font(AppTheme.Fonts.captionSans)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .kerning(0.8)

                    if let reflection = lastWeekReflection {
                        NavigationLink(value: AppDestination.weeklyMirror(weekStart: reflection.weekStartDate)) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(reflection.summaryText)
                                    .font(AppTheme.Fonts.bodySerif)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                    .lineLimit(3)
                                    .lineSpacing(4)

                                HStack(spacing: 6) {
                                    Text("Read reflection")
                                        .font(AppTheme.Fonts.captionSans)
                                        .foregroundStyle(AppTheme.Colors.accent)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.Colors.accent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(AppTheme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Your first weekly reflection will appear here after you've logged a few days.")
                            .font(AppTheme.Fonts.bodySerif)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineSpacing(4)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(AppTheme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                    }
                }
            }
            .padding(.horizontal, AppTheme.Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    NavigationLink(value: AppDestination.history) {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    NavigationLink(value: AppDestination.settings) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
    }

    private func isoWeekStart(for date: Date) -> Date {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .modelContainer(for: [DailyEntry.self, WeeklyReflection.self], inMemory: true)
            .environment(AppViewModel())
    }
}
