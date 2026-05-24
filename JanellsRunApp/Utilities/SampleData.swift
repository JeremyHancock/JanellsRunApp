import Foundation
import SwiftData

enum SampleData {
    static func loadIfNeeded(into context: ModelContext) {
        let key = "sampleDataLoaded"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let richmond = RaceEvent(name: "Richmond Half Marathon", location: "Richmond, VA", typicalDistance: 13.1)
        let shamrock = RaceEvent(name: "Shamrock Marathon", location: "Virginia Beach, VA", typicalDistance: 26.2)
        let ukrops = RaceEvent(name: "Ukrop's Monument Ave 10K", location: "Richmond, VA", typicalDistance: 6.2)
        let turkey = RaceEvent(name: "Richmond Turkey Trot", location: "Richmond, VA", typicalDistance: 3.1)

        let events = [richmond, shamrock, ukrops, turkey]
        for event in events { context.insert(event) }

        let runs: [(RaceEvent?, Double, String, Int, Bool)] = [
            // Richmond Half Marathon - 3 years of progression
            (richmond, 13.1, "2023-11-11", 7320, true),   // 2:02:00
            (richmond, 13.1, "2024-11-09", 7080, true),   // 1:58:00
            (richmond, 13.1, "2025-11-08", 6900, true),   // 1:55:00

            // Shamrock Marathon
            (shamrock, 26.2, "2024-03-17", 15300, true),  // 4:15:00
            (shamrock, 26.2, "2025-03-16", 14820, true),  // 4:07:00

            // Ukrop's 10K - 4 years
            (ukrops, 6.2, "2022-04-23", 3360, true),      // 00:56:00
            (ukrops, 6.2, "2023-04-22", 3240, true),      // 00:54:00
            (ukrops, 6.2, "2024-04-27", 3120, true),      // 00:52:00
            (ukrops, 6.2, "2025-04-26", 3060, true),      // 00:51:00

            // Turkey Trot 5K
            (turkey, 3.1, "2023-11-23", 1620, true),      // 00:27:00
            (turkey, 3.1, "2024-11-28", 1560, true),      // 00:26:00
            (turkey, 3.1, "2025-11-27", 1500, true),      // 00:25:00

            // Training runs
            (nil, 3.1, "2025-10-01", 1680, false),        // 00:28:00
            (nil, 4.0, "2025-10-05", 2280, false),        // 00:38:00
            (nil, 5.0, "2025-10-12", 2880, false),        // 00:48:00
            (nil, 3.1, "2025-10-15", 1650, false),        // 00:27:30
            (nil, 6.2, "2025-10-19", 3480, false),        // 00:58:00
            (nil, 3.1, "2025-10-22", 1620, false),        // 00:27:00
            (nil, 8.0, "2025-10-26", 4560, false),        // 01:16:00
            (nil, 3.1, "2025-11-02", 1590, false),        // 00:26:30
            (nil, 10.0, "2025-11-05", 5700, false),       // 01:35:00
            (nil, 3.1, "2025-11-10", 1560, false),        // 00:26:00
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for (event, distance, dateStr, duration, isRace) in runs {
            guard let date = dateFormatter.date(from: dateStr) else { continue }
            let run = Run(
                distance: distance,
                date: date,
                durationSeconds: duration,
                isRace: isRace,
                event: event
            )
            context.insert(run)
        }
    }
}
