import Foundation
import os

// MARK: - Value Type for Import

nonisolated struct DailyEntryImport {
    let date: Date
    let moodScore: Double
    let energyLevel: Double
    let oneWord: String
    let whatMattered: String
    let voiceNoteTranscript: String?
}

/// Result of parsing an import file: the records that parsed successfully,
/// plus how many rows had to be skipped because they were malformed.
nonisolated struct CSVImportResult {
    let records: [DailyEntryImport]
    let skippedRowCount: Int
}

// MARK: - CSVService

actor CSVService {

    static let shared = CSVService()

    private let csvFileName = "reflections.csv"

    private var documentsURL: URL {
        get throws {
            guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw CSVError.documentsDirectoryUnavailable
            }
            return url
        }
    }

    // MARK: Export

    /// Serialises all entries to CSV and writes to the app's Documents folder.
    /// - Returns: The file URL for sharing.
    func exportEntries(_ entries: [DailyEntry]) async throws -> URL {
        let fileURL = try documentsURL.appendingPathComponent(csvFileName)

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
            AppLog.csv.error("exportEntries: failed to UTF-8 encode \(lines.count, privacy: .public) lines")
            throw CSVError.encodingFailed
        }

        do {
            try data.write(to: fileURL, options: .atomicWrite)
        } catch {
            AppLog.csv.error("exportEntries: write failed for \(entries.count, privacy: .public) entries: \(String(describing: error), privacy: .public)")
            throw CSVError.writeFailed(error)
        }
        return fileURL
    }

    // MARK: Import

    /// Parses a CSV file at the given URL and returns the records that parsed successfully,
    /// along with a count of rows that had to be skipped.
    /// The caller is responsible for inserting the records into a `ModelContext`.
    func importEntries(from url: URL) async throws -> CSVImportResult {
        let accessed = url.startAccessingSecurityScopedResource()
        if !accessed {
            AppLog.csv.warning("importEntries: startAccessingSecurityScopedResource returned false for \(url.lastPathComponent, privacy: .public)")
        }
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            AppLog.csv.error("importEntries: failed to read file: \(String(describing: error), privacy: .public)")
            throw CSVError.readFailed(error)
        }

        guard let content = String(data: data, encoding: .utf8) else {
            AppLog.csv.error("importEntries: file is not valid UTF-8")
            throw CSVError.decodingFailed
        }

        var rows = parseCSVRows(content)
        guard !rows.isEmpty else {
            throw CSVError.noValidRows
        }

        // Drop the header row only if it actually looks like one — a headerless
        // file shouldn't silently lose its first data row.
        if rows[0].first?.lowercased() == "date" {
            rows.removeFirst()
        } else {
            AppLog.csv.warning("importEntries: no header row found, treating first row as data")
        }

        let formatter = ISO8601DateFormatter()
        var results: [DailyEntryImport] = []
        var skippedRowCount = 0

        for (index, columns) in rows.enumerated() {
            guard columns.count >= 5 else {
                AppLog.csv.warning("importEntries: row \(index, privacy: .public) skipped — expected at least 5 columns, found \(columns.count, privacy: .public)")
                skippedRowCount += 1
                continue
            }

            guard let date = formatter.date(from: columns[0]) else {
                AppLog.csv.warning("importEntries: row \(index, privacy: .public) skipped — unparsable date")
                skippedRowCount += 1
                continue
            }
            guard let moodScore = Double(columns[1]) else {
                AppLog.csv.warning("importEntries: row \(index, privacy: .public) skipped — unparsable moodScore")
                skippedRowCount += 1
                continue
            }
            guard let energyLevel = Double(columns[2]) else {
                AppLog.csv.warning("importEntries: row \(index, privacy: .public) skipped — unparsable energyLevel")
                skippedRowCount += 1
                continue
            }

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

        guard !results.isEmpty else {
            throw CSVError.noValidRows
        }

        return CSVImportResult(records: results, skippedRowCount: skippedRowCount)
    }

    // MARK: Private helpers

    /// Wraps a field in quotes if it contains a comma, newline, or quote — the counterpart
    /// to `parseCSVRows`, which must tokenize across those same newlines rather than
    /// pre-splitting the document, or a quoted multi-line field gets torn across two rows.
    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    /// RFC 4180 compliant parser over the entire document (handles quoted fields with
    /// embedded commas/newlines). Quote state carries across line breaks, so a quoted
    /// field containing a newline survives an export → import round trip.
    private func parseCSVRows(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var index = content.startIndex
        var sawAnyFieldOnLine = false

        func endField() {
            fields.append(current)
            current = ""
        }

        func endRow() {
            endField()
            // Skip fully blank lines (a single empty field) rather than emitting an empty row.
            if !(fields.count == 1 && fields[0].isEmpty) {
                rows.append(fields)
            }
            fields = []
            sawAnyFieldOnLine = false
        }

        while index < content.endIndex {
            let char = content[index]
            if inQuotes {
                if char == "\"" {
                    let nextIndex = content.index(after: index)
                    if nextIndex < content.endIndex && content[nextIndex] == "\"" {
                        current.append("\"")
                        index = content.index(after: nextIndex)
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
                    sawAnyFieldOnLine = true
                } else if char == "," {
                    endField()
                    sawAnyFieldOnLine = true
                } else if char == "\n" {
                    endRow()
                } else if char == "\r" {
                    // Swallow bare \r; the following \n (if any) ends the row.
                } else {
                    current.append(char)
                    sawAnyFieldOnLine = true
                }
            }
            index = content.index(after: index)
        }

        if inQuotes {
            AppLog.csv.warning("importEntries: file ended inside a quoted field")
        }
        if sawAnyFieldOnLine || !current.isEmpty || !fields.isEmpty {
            endRow()
        }

        return rows
    }
}

// MARK: - Errors

enum CSVError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case readFailed(Error)
    case writeFailed(Error)
    case noValidRows
    case documentsDirectoryUnavailable

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode CSV data."
        case .decodingFailed:
            return "Failed to decode the selected file."
        case .readFailed:
            return "Couldn't read the selected file."
        case .writeFailed:
            return "Couldn't save the export file."
        case .noValidRows:
            return "No valid entries were found in that file."
        case .documentsDirectoryUnavailable:
            return "Couldn't access storage on this device."
        }
    }
}
