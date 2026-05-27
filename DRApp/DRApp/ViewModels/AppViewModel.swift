import SwiftUI

// MARK: - Navigation Destinations

enum AppDestination: Hashable {
    case dailyEntry
    case weeklyMirror(weekStart: Date)
    case history
    case settings
}

// MARK: - AppViewModel

@Observable
@MainActor
final class AppViewModel {

    // MARK: Stored via UserDefaults
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    // MARK: Navigation
    var navigationPath = NavigationPath()

    func navigateTo(_ destination: AppDestination) {
        navigationPath.append(destination)
    }

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func resetNavigation() {
        navigationPath = NavigationPath()
    }

    // MARK: Onboarding

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
