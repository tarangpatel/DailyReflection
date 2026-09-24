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

    /// All fonts are text-style-based so they scale with the user's preferred Dynamic Type size.
    enum Fonts {
        /// Serif font for narrative / reflection text, scaled relative to the nearest matching text style.
        static func reflectionSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(textStyle(for: size), design: .serif, weight: weight)
        }

        /// Sans-serif font for UI chrome, scaled relative to the nearest matching text style.
        static func uiSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(textStyle(for: size), design: .default, weight: weight)
        }

        static let titleSerif: Font    = .system(.largeTitle, design: .serif, weight: .light)
        static let headingSerif: Font  = .system(.title2, design: .serif)
        static let bodySerif: Font     = .system(.body, design: .serif)
        static let captionSans: Font   = .system(.footnote, design: .default)
        static let labelSans: Font     = .system(.subheadline, design: .default)
        static let buttonSans: Font    = .system(.callout, design: .default, weight: .medium)

        private static func textStyle(for size: CGFloat) -> Font.TextStyle {
            switch size {
            case 32...:   return .largeTitle
            case 28..<32: return .title
            case 22..<28: return .title2
            case 20..<22: return .title3
            case 17..<20: return .body
            case 16..<17: return .callout
            case 15..<16: return .subheadline
            case 13..<15: return .footnote
            case 11..<13: return .caption
            default:      return .caption2
            }
        }
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
