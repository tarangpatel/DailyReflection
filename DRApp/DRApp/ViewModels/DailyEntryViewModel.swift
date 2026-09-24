import SwiftUI
import SwiftData

@Observable
@MainActor
final class DailyEntryViewModel {

    // MARK: Form State
    var moodScore: Double = 0.5
    var energyLevel: Double = 0.5
    var oneWord: String = ""
    var whatMattered: String = ""

    /// Manages audio recording and playback for the optional voice note.
    var voiceNoteService = VoiceNoteService()

    var isSaving: Bool = false
    var didSave: Bool = false
    var saveErrorMessage: String? = nil

    /// If an entry already exists for today, this holds it (edit mode).
    var existingEntry: DailyEntry? = nil

    var isEditMode: Bool { existingEntry != nil }

    var isSaveEnabled: Bool {
        !oneWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !whatMattered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Load existing entry for today

    func loadTodayEntry(from entries: [DailyEntry]) {
        let todayStart = Calendar.current.startOfDay(for: Date())
        if let existing = entries.first(where: { $0.date == todayStart }) {
            existingEntry = existing
            moodScore    = existing.moodScore
            energyLevel  = existing.energyLevel
            oneWord      = existing.oneWord
            whatMattered = existing.whatMattered
            if let data = existing.voiceNoteData {
                voiceNoteService.loadAudioData(data, transcript: existing.voiceNoteTranscript)
            }
        }
    }

    // MARK: Save

    func saveEntry(context: ModelContext) async {
        guard isSaveEnabled else { return }
        isSaving = true
        defer { isSaving = false }

        let noteData = voiceNoteService.audioData
        let noteTranscript = noteData == nil ? nil : voiceNoteService.transcript

        if let existing = existingEntry {
            existing.moodScore    = moodScore
            existing.energyLevel  = energyLevel
            existing.oneWord      = oneWord
            existing.whatMattered = whatMattered
            existing.voiceNoteData = noteData
            existing.voiceNoteTranscript = noteTranscript
        } else {
            let entry = DailyEntry(
                date: Date(),
                moodScore: moodScore,
                energyLevel: energyLevel,
                oneWord: oneWord,
                whatMattered: whatMattered,
                voiceNoteData: noteData,
                voiceNoteTranscript: noteTranscript
            )
            context.insert(entry)
        }

        if context.saveLogging("saveEntry") {
            didSave = true
        } else {
            saveErrorMessage = "Your entry couldn't be saved. Your text is still here — try again."
        }
    }
}
