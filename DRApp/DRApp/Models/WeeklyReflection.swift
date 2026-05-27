import Foundation
import SwiftData

@Model
final class WeeklyReflection {
    var id: UUID
    /// Monday of the ISO week this reflection covers
    var weekStartDate: Date
    var summaryText: String
    /// "yes" | "somewhat" | "no" | nil (not yet rated)
    var accuracyRating: String?
    var averageMood: Double
    var averageEnergy: Double

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        summaryText: String,
        accuracyRating: String? = nil,
        averageMood: Double,
        averageEnergy: Double
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.summaryText = summaryText
        self.accuracyRating = accuracyRating
        self.averageMood = averageMood
        self.averageEnergy = averageEnergy
    }
}
