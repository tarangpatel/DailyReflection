import Foundation
import SwiftData

// MARK: - Supporting Enums

enum EmotionalStyle: String, CaseIterable, Identifiable {
    case thinkQuietly   = "I think through them quietly"
    case talkOut        = "I talk them out"
    case writeOut       = "I write them out"
    case avoid          = "I tend to avoid them"
    case unsure         = "I'm not sure"

    var id: String { rawValue }
}

enum TonePreference: String, CaseIterable, Identifiable {
    case quietGrounding = "Quiet and grounding"
    case softPoetic     = "Soft and poetic"
    case clearSimple    = "Clear and simple"
    case analytical     = "Slightly analytical"

    var id: String { rawValue }
}

// MARK: - Model

/// Stores the result of the onboarding questionnaire.
/// Only one instance is expected per install (created once on onboarding completion).
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var whyHereText: String
    /// Raw value of `EmotionalStyle`
    var emotionalStyle: String
    /// Raw value of `TonePreference`
    var tonePreference: String

    init(
        id: UUID = UUID(),
        whyHereText: String,
        emotionalStyle: String,
        tonePreference: String
    ) {
        self.id = id
        self.name = "Anonymous"
        self.whyHereText = whyHereText
        self.emotionalStyle = emotionalStyle
        self.tonePreference = tonePreference
    }

    var emotionalStyleEnum: EmotionalStyle? {
        EmotionalStyle(rawValue: emotionalStyle)
    }

    var tonePreferenceEnum: TonePreference? {
        TonePreference(rawValue: tonePreference)
    }
}
