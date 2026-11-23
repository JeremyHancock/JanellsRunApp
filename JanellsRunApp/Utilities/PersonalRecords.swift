import Foundation

enum PersonalRecords {
    /// Runs that can hold a PR. Races always can. Training runs, when included,
    /// only count at a standard distance or one that has also been raced, so
    /// every odd-length training run doesn't become its own record.
    static func eligibleRuns(from runs: [Run], includeTraining: Bool) -> [Run] {
        let races = runs.filter(\.isRace)
        guard includeTraining else { return races }

        let racedKeys = Set(races.map { DistancePreset.groupingKey(forMiles: $0.distance) })
        return runs.filter { run in
            run.isRace
                || DistancePreset.matchingPreset(forMiles: run.distance) != nil
                || racedKeys.contains(DistancePreset.groupingKey(forMiles: run.distance))
        }
    }

    /// An event's PR: the fastest run at its main distance. That is the event's
    /// typical distance when it has runs there, otherwise the distance run most
    /// often (the longer one on a tie). Times at other distances don't compete.
    static func eventBest(in runs: [Run], typicalDistance: Double?) -> Run? {
        let byDistance = Dictionary(grouping: runs) { DistancePreset.groupingKey(forMiles: $0.distance) }
        let typicalKey = typicalDistance.map { DistancePreset.groupingKey(forMiles: $0) }

        let mainGroup = typicalKey.flatMap { byDistance[$0] }
            ?? byDistance.values.max { a, b in
                a.count != b.count ? a.count < b.count : (a.first?.distance ?? 0) < (b.first?.distance ?? 0)
            }
        return mainGroup?.min { $0.durationSeconds < $1.durationSeconds }
    }

    static func hasMultipleDistances(_ runs: [Run]) -> Bool {
        Set(runs.map { DistancePreset.groupingKey(forMiles: $0.distance) }).count > 1
    }

    /// The fastest run at each distance, longest distance first.
    static func best(in runs: [Run]) -> [Run] {
        var bestByDistance: [String: Run] = [:]
        for run in runs {
            let key = DistancePreset.groupingKey(forMiles: run.distance)
            if let existing = bestByDistance[key], existing.durationSeconds <= run.durationSeconds {
                continue
            }
            bestByDistance[key] = run
        }
        return bestByDistance.values.sorted { $0.distance > $1.distance }
    }
}
