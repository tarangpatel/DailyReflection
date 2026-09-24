//
//  DRAppTests.swift
//  DRAppTests
//
//  Created by Tarang Patel on 2026-05-18.
//

import Testing
import Foundation
@testable import DRApp

struct DRAppTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    // MARK: - CSV round trip

    @Test func csvRoundTripPreservesMultiLineAndCommaFields() async throws {
        let day1 = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let day2 = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_700_100_000))

        let entries = [
            DailyEntry(
                date: day1,
                moodScore: 0.5,
                energyLevel: 0.6,
                oneWord: "calm",
                whatMattered: "line one\nline two"
            ),
            DailyEntry(
                date: day2,
                moodScore: 0.7,
                energyLevel: 0.4,
                oneWord: "busy",
                whatMattered: "a, b, \"quoted\"",
                voiceNoteTranscript: "first sentence.\nsecond sentence."
            )
        ]

        let url = try await CSVService.shared.exportEntries(entries)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await CSVService.shared.importEntries(from: url)
        #expect(result.skippedRowCount == 0)
        #expect(result.records.count == 2)

        let sorted = result.records.sorted { $0.date < $1.date }
        #expect(sorted[0].whatMattered == "line one\nline two")
        #expect(sorted[1].whatMattered == "a, b, \"quoted\"")
        #expect(sorted[1].voiceNoteTranscript == "first sentence.\nsecond sentence.")
    }

    @Test func malformedRowsAreSkippedNotFatal() async throws {
        let csv = """
        date,moodScore,energyLevel,oneWord,whatMattered,voiceNoteTranscript
        2024-01-01T00:00:00Z,0.5,0.5,ok,fine,
        not-a-date,0.5,0.5,bad,date row,
        2024-01-02T00:00:00Z,not-a-number,0.5,bad,mood row,
        2024-01-03T00:00:00Z,0.5
        """
        let url = try writeTempCSV(csv)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await CSVService.shared.importEntries(from: url)
        #expect(result.records.count == 1)
        #expect(result.skippedRowCount == 3)
        #expect(result.records[0].oneWord == "ok")
    }

    @Test func headerlessFileKeepsFirstDataRow() async throws {
        let csv = "2024-01-01T00:00:00Z,0.5,0.5,ok,fine,\n"
        let url = try writeTempCSV(csv)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await CSVService.shared.importEntries(from: url)
        #expect(result.records.count == 1)
        #expect(result.records[0].oneWord == "ok")
    }

    @Test func fullyMalformedFileThrowsNoValidRows() async throws {
        let csv = """
        date,moodScore,energyLevel,oneWord,whatMattered,voiceNoteTranscript
        not-a-date,not-a-number,not-a-number,bad,bad,
        """
        let url = try writeTempCSV(csv)
        defer { try? FileManager.default.removeItem(at: url) }

        await #expect(throws: CSVError.self) {
            _ = try await CSVService.shared.importEntries(from: url)
        }
    }

    // MARK: - Helpers

    private func writeTempCSV(_ content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("csv")
        try content.data(using: .utf8)!.write(to: url)
        return url
    }
}
