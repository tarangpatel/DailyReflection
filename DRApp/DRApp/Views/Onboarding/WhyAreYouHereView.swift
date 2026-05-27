import SwiftUI

struct WhyAreYouHereView: View {
    @Binding var text: String
    let canContinue: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Fonts.uiSans(17))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.top, 16)

            Text("What brings you here?")
                .font(AppTheme.Fonts.headingSerif)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            TextEditor(text: $text)
                .font(AppTheme.Fonts.bodySerif)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                .frame(minHeight: 140)
                .overlay(
                    Group {
                        if text.isEmpty {
                            Text("I want more clarity in my life...")
                                .font(AppTheme.Fonts.bodySerif)
                                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))
                                .padding(.leading, 8)
                                .padding(.top, 10)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                )

            Spacer()

            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(AppTheme.Fonts.buttonSans)
                .foregroundStyle(canContinue ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
            }
            .disabled(!canContinue)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appBackground()
    }
}

#Preview {
    WhyAreYouHereView(
        text: .constant(""),
        canContinue: false,
        onBack: {},
        onContinue: {}
    )
}
