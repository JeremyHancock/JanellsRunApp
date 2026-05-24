import Foundation

struct HealthKitWorkout: Identifiable {
    let id: String
    let date: Date
    let distance: Double
    let durationSeconds: Int
}
