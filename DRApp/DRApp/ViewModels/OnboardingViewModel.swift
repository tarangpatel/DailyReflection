import SwiftUI
import SwiftData

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case whyHere
    case emotionalStyle
    case tonePreference
}

// MARK: - OnboardingViewModel

@Observable
@MainActor
final class OnboardingViewModel {

    var step: OnboardingStep = .welcome

    // Form state
    var whyHereText: String = ""
    var selectedEmotionalStyle: EmotionalStyle? = nil
    var selectedTone: TonePreference? = nil
    var errorMessage: String? = nil

    var canContinueWhyHere: Bool { !whyHereText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var canContinueEmotionalStyle: Bool { selectedEmotionalStyle != nil }
    var canContinueTone: Bool { selectedTone != nil }

    // MARK: Navigation

    func advance() {
        let all = OnboardingStep.allCases
        guard let current = all.firstIndex(of: step), current + 1 < all.count else { return }
        withAnimation(AppTheme.Animation.slowFade) {
            step = all[current + 1]
        }
    }

    func goBack() {
        let all = OnboardingStep.allCases
        guard let current = all.firstIndex(of: step), current > 0 else { return }
        withAnimation(AppTheme.Animation.slowFade) {
            step = all[current - 1]
        }
    }

    // MARK: Completion

    func completeOnboarding(context: ModelContext, appViewModel: AppViewModel) async {
        let profile = UserProfile(
            whyHereText: whyHereText,
            emotionalStyle: selectedEmotionalStyle?.rawValue ?? "",
            tonePreference: selectedTone?.rawValue ?? ""
        )
        context.insert(profile)
        if context.saveLogging("completeOnboarding") {
            appViewModel.completeOnboarding()
        } else {
            errorMessage = "Something went wrong saving your answers. Please try again."
        }
    }
}
