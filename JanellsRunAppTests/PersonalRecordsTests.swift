import Foundation
import Testing
@testable import JanellsRunApp

struct PersonalRecordsTests {
    private func run(_ miles: Double, _ seconds: Int, race: Bool = true) -> Run {
        Run(distance: miles, date: Date(), durationSeconds: seconds, isRace: race)
    }

    @Test func nearPresetDistancesShareOneRecord() {
        let best = PersonalRecords.best(in: [run(3.1, 1500), run(3.12, 1450), run(6.2, 3200)])
        #expect(best.map(\.durationSeconds) == [3200, 1450])
    }

    @Test func trainingRunsAreLeftOutByDefault() {
        let runs = [run(3.1, 1500), run(3.1, 1400, race: false)]
        let best = PersonalRecords.best(in: PersonalRecords.eligibleRuns(from: runs, includeTraining: false))
        #expect(best.map(\.durationSeconds) == [1500])
    }

    @Test func trainingRunsCountAtStandardAndRacedDistances() {
        let runs = [
            run(3.1, 1500),
            run(3.1, 1400, race: false),   // standard distance
            run(10.0, 5400),
            run(10.0, 5300, race: false),  // raced distance
            run(4.3, 2400, race: false),   // neither
        ]
        let best = PersonalRecords.best(in: PersonalRecords.eligibleRuns(from: runs, includeTraining: true))
        #expect(best.map(\.durationSeconds) == [5300, 1400])
    }

    @Test func eventBestIgnoresFasterTimesAtOtherDistances() {
        // Two half marathons and one 5K under the same event
        let runs = [run(13.1, 7200), run(13.1, 7000), run(3.1, 1500)]
        #expect(PersonalRecords.eventBest(in: runs, typicalDistance: 13.1)?.durationSeconds == 7000)
        // With no typical distance, the distance run most often wins
        #expect(PersonalRecords.eventBest(in: runs, typicalDistance: nil)?.durationSeconds == 7000)
        #expect(PersonalRecords.hasMultipleDistances(runs))
    }

    @Test func eventBestFallsBackWhenNothingMatchesTypicalDistance() {
        let runs = [run(6.2, 3500), run(6.2, 3400)]
        #expect(PersonalRecords.eventBest(in: runs, typicalDistance: 13.1)?.durationSeconds == 3400)
        #expect(!PersonalRecords.hasMultipleDistances(runs))
        #expect(PersonalRecords.eventBest(in: [], typicalDistance: nil) == nil)
    }
}
