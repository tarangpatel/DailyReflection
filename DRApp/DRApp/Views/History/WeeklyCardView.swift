import SwiftUI

/// Horizontal strip of mood colors — one segment per day entry in the week.
struct MoodColorStripView: View {
    let moodScores: [Double]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(moodScores.enumerated()), id: \.offset) { _, score in
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.Colors.moodStripColor(for: score))
                    .frame(height: 6)
            }
            // Fill remaining days with placeholder segments
            ForEach(0..<max(0, 7 - moodScores.count), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.Colors.textSecondary.opacity(0.15))
                    .frame(height: 6)
            }
        }
    }
}

struct WeeklyCardView: View {
    let group: WeekGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Week label
            Text(group.weekLabel)
                .font(AppTheme.Fonts.captionSans)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.8)

            // Preview text
            if let reflection = group.reflection {
                Text(reflection.summaryText)
                    .font(AppTheme.Fonts.bodySerif)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .lineSpacing(4)
            } else {
                Text("\(group.entries.count) \(group.entries.count == 1 ? "entry" : "entries") this week")
                    .font(AppTheme.Fonts.bodySerif)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            // Mood color strip
            MoodColorStripView(
                moodScores: group.entries
                    .sorted { $0.date < $1.date }
                    .map(\.moodScore)
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
    }
}

#Preview {
    WeeklyCardView(group: WeekGroup(
        weekStart: Date(),
        entries: [],
        reflection: nil
    ))
    .padding()
}
