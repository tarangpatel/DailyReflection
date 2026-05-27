import SwiftUI

struct WelcomeView: View {
    let onBegin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 24) {
                Text("Life Intelligence OS")
                    .font(AppTheme.Fonts.titleSerif)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("A quiet space to reflect,\nnotice patterns, and understand\nyourself over time.")
                    .font(AppTheme.Fonts.bodySerif)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineSpacing(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Layout.horizontalPadding)

            Spacer()
            Spacer()

            Button(action: onBegin) {
                HStack(spacing: 8) {
                    Text("Begin")
                    Image(systemName: "arrow.right")
                }
                .font(AppTheme.Fonts.buttonSans)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(AppTheme.Colors.surface)
                .clipShape(Capsule())
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground()
    }
}

#Preview {
    WelcomeView(onBegin: {})
}
