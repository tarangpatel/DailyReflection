import Foundation
import SwiftData

@Model
final class DailyEntry {
    var id: UUID
    /// Calendar day of the entry (time zeroed to midnight)
    var date: Date
    /// Mood score in range 0.0 (low) to 1.0 (high)
    var moodScore: Double
    /// Energy level in range 0.0 (low) to 1.0 (high)
    var energyLevel: Double
    var oneWord: String
    var whatMattered: String
    /// Encoded M4A audio data for the optional voice note.
    var voiceNoteData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        moodScore: Double = 0.5,
        energyLevel: Double = 0.5,
        oneWord: String = "",
        whatMattered: String = "",
        voiceNoteData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.moodScore = moodScore
        self.energyLevel = energyLevel
        self.oneWord = oneWord
        self.whatMattered = whatMattered
        self.voiceNoteData = voiceNoteData
        self.createdAt = createdAt
    }
}
