import Foundation
import FoundationModels

// MARK: - Week Tone Classification

private enum WeekTone {
    case positive        // avg mood ≥ 0.65 and avg energy ≥ 0.55
    case lightPositive   // avg mood 0.50–0.64
    case uneven          // large variance in mood or energy
    case heavy           // avg mood < 0.40
    case neutral         // everything else
}

// MARK: - ReflectionNarrativeService

actor ReflectionNarrativeService {

    static let shared = ReflectionNarrativeService()

    // MARK: - Public API

    /// Generates a ~150-word narrative paragraph for a given set of daily entries.
    /// Uses Apple's on-device Foundation Model when available; falls back to the
    /// template-based approach otherwise.
    /// - Parameters:
    ///   - entries: The daily entries belonging to the target week.
    ///   - weekStartDate: Monday of the ISO week.
    /// - Returns: A narrative string suitable for display in the Weekly Mirror.
    func generateNarrative(for entries: [DailyEntry], weekStartDate: Date) async -> String {
        guard !entries.isEmpty else {
            return "This week was quiet — no entries were recorded. Sometimes silence is its own kind of reflection."
        }

        let sorted = entries.sorted { $0.date < $1.date }
        let avgMood   = sorted.map(\.moodScore).reduce(0, +) / Double(sorted.count)
        let avgEnergy = sorted.map(\.energyLevel).reduce(0, +) / Double(sorted.count)
        let moodVariance = variance(sorted.map(\.moodScore))
        let tone = classify(avgMood: avgMood, avgEnergy: avgEnergy, moodVariance: moodVariance)
        let weekLabel = weekRangeLabel(from: weekStartDate)

        // Attempt on-device Apple Foundation Model generation
        if case .available = SystemLanguageModel.default.availability {
            if let aiNarrative = await generateWithFoundationModel(
                entries: sorted,
                weekLabel: weekLabel,
                avgMood: avgMood,
                avgEnergy: avgEnergy,
                tone: tone
            ) {
                return aiNarrative
            }
        }

        // Fallback: template-based narrative
        let keywords = extractKeywords(from: sorted.map(\.whatMattered))
        return buildNarrative(
            weekLabel: weekLabel,
            tone: tone,
            avgMood: avgMood,
            avgEnergy: avgEnergy,
            keywords: keywords,
            entryCount: sorted.count,
            days: sorted
        )
    }

    // MARK: - Foundation Model Generation

    private func generateWithFoundationModel(
        entries: [DailyEntry],
        weekLabel: String,
        avgMood: Double,
        avgEnergy: Double,
        tone: WeekTone
    ) async -> String? {
        let prompt = buildPrompt(
            entries: entries,
            weekLabel: weekLabel,
            avgMood: avgMood,
            avgEnergy: avgEnergy,
            tone: tone
        )

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            // Model error — fall through to template
            return nil
        }
    }

    /// Builds a structured prompt so the on-device model produces a ~150-word
    /// personal, introspective narrative.
    private func buildPrompt(
        entries: [DailyEntry],
        weekLabel: String,
        avgMood: Double,
        avgEnergy: Double,
        tone: WeekTone
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        let entryLines = entries.map { entry -> String in
            let dayName = formatter.string(from: entry.date)
            let moodPct = Int(entry.moodScore * 100)
            let energyPct = Int(entry.energyLevel * 100)
            var line = "- \(dayName): mood \(moodPct)%, energy \(energyPct)%"
            if !entry.oneWord.isEmpty {
                line += ", one word: \(entry.oneWord)"
            }
            if !entry.whatMattered.isEmpty {
                line += ", what mattered: \(entry.whatMattered)"
            }
            return line
        }.joined(separator: "\n")

        let toneHint: String
        switch tone {
        case .positive:      toneHint = "uplifting and warm"
        case .lightPositive: toneHint = "gentle and encouraging"
        case .uneven:        toneHint = "honest and grounding"
        case .heavy:         toneHint = "compassionate and soft"
        case .neutral:       toneHint = "calm and reflective"
        }

        return """
        You are a compassionate journaling companion writing a weekly reflection for a person.

        Week: \(weekLabel)
        Average mood: \(Int(avgMood * 100))%
        Average energy: \(Int(avgEnergy * 100))%
        Overall tone of the week: \(toneHint)

        Daily entries:
        \(entryLines)

        Write a single paragraph of approximately 150 words that:
        - Reflects on the week with warmth and psychological sensitivity
        - Weaves in themes or words from the daily entries naturally
        - Uses second-person ("you") voice, present or past tense
        - Does NOT use bullet points, headers, or any markdown formatting
        - Ends with a brief, grounding closing thought
        - Does NOT mention specific percentages or raw numbers

        Paragraph:
        """
    }

    // MARK: - Classification

    private func classify(avgMood: Double, avgEnergy: Double, moodVariance: Double) -> WeekTone {
        if avgMood >= 0.65 && avgEnergy >= 0.55 { return .positive }
        if avgMood < 0.35 { return .heavy }
        if moodVariance > 0.06 { return .uneven }
        if avgMood >= 0.50 { return .lightPositive }
        return .neutral
    }

    // MARK: - Keyword Extraction

    private func extractKeywords(from texts: [String]) -> [String] {
        let stopWords: Set<String> = [
            "i","a","an","the","and","or","but","in","on","at","to","for","of","with",
            "my","me","it","is","was","were","had","have","has","be","been","being",
            "that","this","those","these","they","we","you","he","she","not","no",
            "so","as","up","do","did","its","by","from","about","into","which","how",
            "what","when","where","there","their","than","then","just","some","like",
            "more","also","after","before","very","really","today","week","day","time"
        ]

        var freq: [String: Int] = [:]
        let words = texts.joined(separator: " ")
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { $0.count > 3 && !stopWords.contains($0) }

        for word in words {
            freq[word, default: 0] += 1
        }

        return freq.sorted { $0.value > $1.value }.prefix(4).map(\.key)
    }

    // MARK: - Template Narrative Builder (Fallback)

    private func buildNarrative(
        weekLabel: String,
        tone: WeekTone,
        avgMood: Double,
        avgEnergy: Double,
        keywords: [String],
        entryCount: Int,
        days: [DailyEntry]
    ) -> String {
        let keywordPhrase: String
        if keywords.isEmpty {
            keywordPhrase = ""
        } else if keywords.count == 1 {
            keywordPhrase = "There was a recurring thread around \(keywords[0])."
        } else {
            let joined = keywords.dropLast().joined(separator: ", ") + " and " + keywords.last!
            keywordPhrase = "Threads of \(joined) kept surfacing through the week."
        }

        let energyDesc = energyDescription(avgEnergy)
        let openingLine: String
        let bodyLine: String
        let closingLine: String

        switch tone {
        case .positive:
            openingLine = "This was a week that carried a quiet brightness."
            bodyLine    = "There was a sense of openness — your energy \(energyDesc), and the mood stayed light across most days."
            closingLine = "Something felt more settled than usual, even in the ordinary moments."

        case .lightPositive:
            openingLine = "This week moved along with a gentle steadiness."
            bodyLine    = "Your mood held mostly even ground, with your energy \(energyDesc) through most of it."
            closingLine = "There were small moments of ease scattered through the days."

        case .uneven:
            openingLine = "This week felt a little uneven — some days carried more than others."
            bodyLine    = "There were visible shifts in how you moved through the days, with energy \(energyDesc) at points."
            closingLine = "Unevenness isn't always a problem. Sometimes it's just honesty."

        case .heavy:
            openingLine = "This was a heavier week."
            bodyLine    = "Something underneath felt weighted — your energy \(energyDesc), and the days carried a certain gravity."
            closingLine = "Weeks like this pass. The noticing itself matters."

        case .neutral:
            openingLine = "This week was quiet and steady."
            bodyLine    = "There wasn't a strong pull in any direction — your energy \(energyDesc) and the mood stayed close to centre."
            closingLine = "Neutral weeks have their own kind of value. Not every week needs to stand out."
        }

        var parts: [String] = [openingLine]
        if !keywordPhrase.isEmpty { parts.append(keywordPhrase) }
        parts.append(bodyLine)
        parts.append(closingLine)

        return parts.joined(separator: " ")
    }

    // MARK: - Helpers

    private func energyDescription(_ avg: Double) -> String {
        switch avg {
        case 0..<0.35:  return "ran low"
        case 0.35..<0.55: return "stayed moderate"
        case 0.55..<0.75: return "held reasonably well"
        default:        return "felt high"
        }
    }

    private func variance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
    }

    private func weekRangeLabel(from weekStart: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(formatter.string(from: weekStart))–\(formatter.string(from: weekEnd))"
    }
}
