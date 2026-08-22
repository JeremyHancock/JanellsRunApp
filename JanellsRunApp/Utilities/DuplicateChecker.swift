import Foundation

enum DuplicateChecker {
    /// Distances closer than this are treated as the same run when comparing
    /// across entry paths (manual, CSV, HealthKit), which record distance with
    /// different precision.
    static let looseDistanceTolerance = 0.05

    static let exactDistanceTolerance = 0.01
    static let durationTolerance = 2

    /// Same calendar day and roughly the same distance. Loose on purpose:
    /// used to warn on manual entry and to hide already-imported workouts
    /// whose HealthKit ID is unknown (e.g. the run came in via CSV).
    static func isLikelyDuplicate(of run: Run, date: Date, distance: Double) -> Bool {
        Calendar.current.isDate(run.date, inSameDayAs: date)
            && abs(run.distance - distance) < looseDistanceTolerance
    }

    /// Same calendar day, same distance, and same duration. Used where two
    /// records claim to be the same logged run (CSV rows vs existing runs),
    /// ignoring time-of-day differences between entry paths.
    static func isSameRun(as run: Run, date: Date, distance: Double, durationSeconds: Int) -> Bool {
        Calendar.current.isDate(run.date, inSameDayAs: date)
            && abs(run.distance - distance) < exactDistanceTolerance
            && abs(run.durationSeconds - durationSeconds) <= durationTolerance
    }

    static func firstLikelyDuplicate(in runs: [Run], date: Date, distance: Double) -> Run? {
        runs.first { isLikelyDuplicate(of: $0, date: date, distance: distance) }
    }
}
