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
