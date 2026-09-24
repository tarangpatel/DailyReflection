import Foundation
import SwiftData
import os

// MARK: - AppLog

enum AppLog {
    nonisolated private static let subsystem = "com.tarangp.DRApp"

    nonisolated static let app            = Logger(subsystem: subsystem, category: "App")
    nonisolated static let persistence    = Logger(subsystem: subsystem, category: "Persistence")
    nonisolated static let csv            = Logger(subsystem: subsystem, category: "CSV")
    nonisolated static let voiceNote      = Logger(subsystem: subsystem, category: "VoiceNote")
    nonisolated static let transcription  = Logger(subsystem: subsystem, category: "Transcription")
    nonisolated static let narrative      = Logger(subsystem: subsystem, category: "Narrative")
    nonisolated static let notifications  = Logger(subsystem: subsystem, category: "Notifications")
}

// MARK: - ModelContext + logging save

extension ModelContext {
    /// Saves and logs on failure. Returns false when the write did not land.
    @discardableResult
    func saveLogging(_ operation: String, logger: Logger = AppLog.persistence) -> Bool {
        do {
            try save()
            return true
        } catch {
            logger.error("\(operation, privacy: .public): context.save failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }
}
