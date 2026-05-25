import Foundation
import SwiftData

@Model
final class RaceEvent {
    var id: UUID = UUID()
    var name: String = ""
    var location: String?
    var typicalDistance: Double?
    @Relationship(deleteRule: .nullify, inverse: \Run.event)
    var runs: [Run]? = []
    var createdAt: Date = Date()

    init(name: String, location: String? = nil, typicalDistance: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.typicalDistance = typicalDistance
        self.runs = [] as [Run]
        self.createdAt = Date()
    }
}
