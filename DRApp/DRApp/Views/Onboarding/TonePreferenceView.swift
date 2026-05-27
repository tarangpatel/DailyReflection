import SwiftUI
import SwiftData

struct TonePreferenceView: View {
    @Binding var selection: TonePreference?
    let canContinue: Bool
    let onBack: () -> Void
    let onEnter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Fonts.uiSans(17))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.top, 16)

            Text("How would you like\nthis space to feel?")
                .font(AppTheme.Fonts.headingSerif)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineSpacing(4)

            VStack(spacing: 6) {
                ForEach(TonePreference.allCases) { tone in
                    SelectionRow(
                        label: tone.rawValue,
                        isSelected: selection == tone,
                        onTap: { selection = tone }
                    )
                }
            }

            Spacer()

            Button(action: onEnter) {
                HStack(spacing: 8) {
                    Text("Enter the space")
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
    TonePreferenceView(
        selection: .constant(nil),
        canContinue: false,
        onBack: {},
        onEnter: {}
    )
}
