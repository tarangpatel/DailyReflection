import SwiftUI

/// Reusable radio-style selection row used in onboarding.
struct SelectionRow: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(label)
                    .font(AppTheme.Fonts.labelSans)
                    .foregroundStyle(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                    .fill(isSelected ? AppTheme.Colors.surface : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Animation.slowFade, value: isSelected)
    }
}

struct EmotionalStyleView: View {
    @Binding var selection: EmotionalStyle?
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

            Text("How do you usually\nprocess emotions?")
                .font(AppTheme.Fonts.headingSerif)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineSpacing(4)

            VStack(spacing: 6) {
                ForEach(EmotionalStyle.allCases) { style in
                    SelectionRow(
                        label: style.rawValue,
                        isSelected: selection == style,
                        onTap: { selection = style }
                    )
                }
            }

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
    EmotionalStyleView(
        selection: .constant(nil),
        canContinue: false,
        onBack: {},
        onContinue: {}
    )
}
