import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel

    @State private var vm = OnboardingViewModel()

    var body: some View {
        Group {
            switch vm.step {
            case .welcome:
                WelcomeView { vm.advance() }
                    .transition(.opacity)

            case .whyHere:
                WhyAreYouHereView(
                    text: $vm.whyHereText,
                    canContinue: vm.canContinueWhyHere,
                    onBack: { vm.goBack() },
                    onContinue: { vm.advance() }
                )
                .transition(.opacity)

            case .emotionalStyle:
                EmotionalStyleView(
                    selection: $vm.selectedEmotionalStyle,
                    canContinue: vm.canContinueEmotionalStyle,
                    onBack: { vm.goBack() },
                    onContinue: { vm.advance() }
                )
                .transition(.opacity)

            case .tonePreference:
                TonePreferenceView(
                    selection: $vm.selectedTone,
                    canContinue: vm.canContinueTone,
                    onBack: { vm.goBack() },
                    onEnter: {
                        Task {
                            await vm.completeOnboarding(context: modelContext, appViewModel: appViewModel)
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(AppTheme.Animation.slowFade, value: vm.step)
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
        .environment(AppViewModel())
}
