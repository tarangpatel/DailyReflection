import SwiftUI

/// Reusable gradient-track slider used for mood and energy input.
struct LabeledSliderView: View {
    let label: String
    @Binding var value: Double
    let leadingLabel: String
    let trailingLabel: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(AppTheme.Fonts.captionSans)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.8)

            ZStack(alignment: .leading) {
                // Gradient track background
                RoundedRectangle(cornerRadius: 4)
                    .fill(gradient)
                    .frame(height: 6)

                Slider(value: $value, in: 0...1)
                    .tint(.clear)
                    .frame(height: 6)
            }

            HStack {
                Text(leadingLabel)
                    .font(AppTheme.Fonts.captionSans)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Spacer()
                Text(trailingLabel)
                    .font(AppTheme.Fonts.captionSans)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
    }
}

private extension LabeledSliderView {
    static var moodGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: 0.67, saturation: 0.25, brightness: 0.75),
                Color(hue: 0.12, saturation: 0.35, brightness: 0.90)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var energyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: 0.55, saturation: 0.15, brightness: 0.80),
                Color(hue: 0.08, saturation: 0.40, brightness: 0.88)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct MoodSliderView: View {
    @Binding var value: Double

    var body: some View {
        LabeledSliderView(
            label: "Mood",
            value: $value,
            leadingLabel: "Low",
            trailingLabel: "High",
            gradient: LabeledSliderView.moodGradient
        )
    }
}

struct EnergySliderView: View {
    @Binding var value: Double

    var body: some View {
        LabeledSliderView(
            label: "Energy",
            value: $value,
            leadingLabel: "Low",
            trailingLabel: "High",
            gradient: LabeledSliderView.energyGradient
        )
    }
}

#Preview {
    VStack(spacing: 32) {
        MoodSliderView(value: .constant(0.7))
        EnergySliderView(value: .constant(0.4))
    }
    .padding()
}
