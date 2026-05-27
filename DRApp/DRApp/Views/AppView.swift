import SwiftUI
import SwiftData

struct AppView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        if appViewModel.hasCompletedOnboarding {
            mainNavigation
        } else {
            OnboardingContainerView()
        }
    }

    @ViewBuilder
    private var mainNavigation: some View {
        @Bindable var vm = appViewModel
        NavigationStack(path: $vm.navigationPath) {
            HomeView()
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .dailyEntry:
                        DailyEntryView()
                    case .weeklyMirror(let weekStart):
                        WeeklyMirrorView(weekStart: weekStart)
                    case .history:
                        HistoryView()
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}

#Preview {
    AppView()
        .modelContainer(
            for: [DailyEntry.self, WeeklyReflection.self, UserProfile.self],
            inMemory: true
        )
        .environment(AppViewModel())
}
