import Foundation

// MARK: - Value Type for Import

struct DailyEntryImport {
    let date: Date
    let moodScore: Double
    let energyLevel: Double
    let oneWord: String
    let whatMattered: String
    let voiceNoteTranscript: String?
}

// MARK: - CSVService

actor CSVService {

    static let shared = CSVService()

    private let csvFileName = "reflections.csv"

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: Export

    /// Serialises all entries to CSV and writes to the app's Documents folder.
    /// - Returns: The file URL for sharing.
    func exportEntries(_ entries: [DailyEntry]) async throws -> URL {
        let fileURL = documentsURL.appendingPathComponent(csvFileName)

        var lines: [String] = ["date,moodScore,energyLevel,oneWord,whatMattered,voiceNoteTranscript"]
        let formatter = ISO8601DateFormatter()

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let dateStr       = formatter.string(from: entry.date)
            let moodStr       = String(format: "%.4f", entry.moodScore)
            let energyStr     = String(format: "%.4f", entry.energyLevel)
            let wordStr       = csvEscape(entry.oneWord)
            let matteredStr   = csvEscape(entry.whatMattered)
            let transcriptStr = csvEscape(entry.voiceNoteTranscript ?? "")
            lines.append("\(dateStr),\(moodStr),\(energyStr),\(wordStr),\(matteredStr),\(transcriptStr)")
        }

        let csvContent = lines.joined(separator: "\n")
        guard let data = csvContent.data(using: .utf8) else {
            throw CSVError.encodingFailed
        }

        try data.write(to: fileURL, options: .atomicWrite)
        return fileURL
    }

    // MARK: Import

    /// Parses a CSV file at the given URL and returns an array of value-type records.
    /// The caller is responsible for inserting the records into a `ModelContext`.
    func importEntries(from url: URL) async throws -> [DailyEntryImport] {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw CSVError.decodingFailed
        }

        var lines = content.components(separatedBy: "\n")
        guard !lines.isEmpty else { return [] }

        // Remove header
        lines.removeFirst()

        let formatter = ISO8601DateFormatter()
        var results: [DailyEntryImport] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let columns = parseCSVLine(trimmed)
            guard columns.count >= 5 else { continue }

            guard
                let date        = formatter.date(from: columns[0]),
                let moodScore   = Double(columns[1]),
                let energyLevel = Double(columns[2])
            else { continue }

            let transcript = columns.count >= 6 ? columns[5] : ""

            results.append(DailyEntryImport(
                date: date,
                moodScore: max(0, min(1, moodScore)),
                energyLevel: max(0, min(1, energyLevel)),
                oneWord: columns[3],
                whatMattered: columns[4],
                voiceNoteTranscript: transcript.isEmpty ? nil : transcript
            ))
        }

        return results
    }

    // MARK: Private helpers

    private func csvEscape(_ value: String) -> String {
        // Wrap in quotes if value contains comma, newline, or quote
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    /// RFC 4180 compliant CSV line parser (handles quoted fields with embedded commas/newlines).
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]
            if inQuotes {
                if char == "\"" {
                    let nextIndex = line.index(after: index)
                    if nextIndex < line.endIndex && line[nextIndex] == "\"" {
                        current.append("\"")
                        index = line.index(after: nextIndex)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
            index = line.index(after: index)
        }
        fields.append(current)
        return fields
    }
}

// MARK: - Errors

enum CSVError: LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode CSV data."
        case .decodingFailed: return "Failed to decode the selected file."
        }
    }
}
