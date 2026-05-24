import Foundation
import SwiftData

@Model
final class Run {
    var id: UUID
    var event: RaceEvent?
    var distance: Double
    var date: Date
    var durationSeconds: Int
    var isRace: Bool
    var healthKitID: String?
    var athlinksResultID: String?
    var notes: String?
    var createdAt: Date

    init(
        distance: Double,
        date: Date,
        durationSeconds: Int,
        isRace: Bool,
        event: RaceEvent? = nil,
        healthKitID: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.distance = distance
        self.date = date
        self.durationSeconds = durationSeconds
        self.isRace = isRace
        self.event = event
        self.healthKitID = healthKitID
        self.notes = notes
        self.createdAt = Date()
    }

    var formattedTime: String {
        TimeFormatter.formatted(durationSeconds)
    }

    var formattedDate: String {
        date.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year(.twoDigits))
    }

    var displayName: String {
        if isRace, let event {
            return event.name
        }
        return "Training"
    }

    var year: Int {
        Calendar.current.component(.year, from: date)
    }
}
