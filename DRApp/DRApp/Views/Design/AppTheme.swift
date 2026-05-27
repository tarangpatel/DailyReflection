import SwiftUI

// MARK: - AppTheme Namespace

enum AppTheme {

    // MARK: Colors

    enum Colors {
        /// Adaptive background gradient for the current mood score (0–1).
        static func moodGradient(for score: Double) -> [Color] {
            let clamped = max(0, min(1, score))
            switch clamped {
            case 0..<0.33:
                return [Color("MoodLow1"), Color("MoodLow2")]
            case 0.33..<0.66:
                return [Color("MoodMid1"), Color("MoodMid2")]
            default:
                return [Color("MoodHigh1"), Color("MoodHigh2")]
            }
        }

        /// Full-screen page background gradient.
        static let backgroundGradient: [Color] = [
            Color("BackgroundTop"),
            Color("BackgroundBottom")
        ]

        static let textPrimary   = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let accent        = Color("Accent")
        static let surface       = Color("Surface")
        static let divider       = Color("Divider")

        /// Mood color strip — used in history cards.
        static func moodStripColor(for score: Double) -> Color {
            let clamped = max(0, min(1, score))
            // Interpolate from soft indigo to warm amber
            return Color(
                hue: 0.67 - 0.52 * clamped,   // indigo → amber hue shift
                saturation: 0.25 + 0.15 * clamped,
                brightness: 0.75 + 0.15 * clamped
            )
        }
    }

    // MARK: Fonts

    enum Fonts {
        /// Serif font for narrative / reflection text.
        static func reflectionSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .serif)
        }

        /// Sans-serif font for UI chrome.
        static func uiSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }

        static let titleSerif: Font    = .system(size: 32, weight: .light, design: .serif)
        static let headingSerif: Font  = .system(size: 22, weight: .regular, design: .serif)
        static let bodySerif: Font     = .system(size: 17, weight: .regular, design: .serif)
        static let captionSans: Font   = .system(size: 13, weight: .regular, design: .default)
        static let labelSans: Font     = .system(size: 15, weight: .regular, design: .default)
        static let buttonSans: Font    = .system(size: 16, weight: .medium, design: .default)
    }

    // MARK: Animation

    enum Animation {
        static let slowFade     = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.85)
    }

    // MARK: Layout

    enum Layout {
        static let horizontalPadding: CGFloat = 28
        static let sectionSpacing: CGFloat    = 32
        static let cornerRadius: CGFloat      = 16
    }
}

// MARK: - Convenience View Modifiers

extension View {
    /// Applies the standard full-screen gradient background.
    func appBackground() -> some View {
        self.background(
            LinearGradient(
                colors: AppTheme.Colors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
