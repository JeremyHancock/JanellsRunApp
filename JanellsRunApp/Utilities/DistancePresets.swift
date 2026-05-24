import Foundation

struct DistancePreset: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let miles: Double
    let kilometers: Double

    static let presets: [DistancePreset] = [
        DistancePreset(label: "5K", miles: 3.1, kilometers: 5.0),
        DistancePreset(label: "8K", miles: 4.97, kilometers: 8.0),
        DistancePreset(label: "10K", miles: 6.2, kilometers: 10.0),
        DistancePreset(label: "Half Marathon", miles: 13.1, kilometers: 21.1),
        DistancePreset(label: "Marathon", miles: 26.2, kilometers: 42.2),
    ]

    static func label(forMiles miles: Double) -> String? {
        presets.first { abs($0.miles - miles) < 0.05 }?.label
    }

    static func matchingPreset(forMiles miles: Double) -> DistancePreset? {
        presets.first { abs($0.miles - miles) < 0.05 }
    }
}
