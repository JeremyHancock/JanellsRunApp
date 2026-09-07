import Testing
import Foundation
@testable import JanellsRunApp

struct AthlinksImporterTests {
    @Test func extractsAthleteIDFromProfileURL() {
        #expect(AthlinksImporter.athleteID(from: "https://www.athlinks.com/athletes/410409327/results") == "410409327")
        #expect(AthlinksImporter.athleteID(from: "athlinks.com/athletes/98765") == "98765")
        #expect(AthlinksImporter.athleteID(from: "  410409327 ") == "410409327")
    }

    @Test func rejectsInputWithoutAnID() {
        #expect(AthlinksImporter.athleteID(from: "") == nil)
        #expect(AthlinksImporter.athleteID(from: "https://www.athlinks.com/") == nil)
        #expect(AthlinksImporter.athleteID(from: "janell") == nil)
    }

    @Test func parsesResultsFromAthlinksPayload() throws {
        let results = try AthlinksImporter.parse(data: Data(samplePayload.utf8))

        #expect(results.count == 3)

        let half = try #require(results.first { $0.id == "572448991" })
        #expect(half.raceName == "2025 Chartway Norfolk Harbor Half Marathon Weekend")
        #expect(half.eventName == "Chartway Norfolk Harbor Half Marathon Weekend")
        #expect(half.location == "Norfolk, VA")
        #expect(half.distanceMiles == 13.1)
        #expect(half.durationSeconds == 6967) // 1:56:07
        #expect(half.isRunning)

        let fiveK = try #require(results.first { $0.id == "217546658" })
        #expect(fiveK.distanceMiles == 3.1)
        #expect(fiveK.durationSeconds == 1692) // 28:12.4 rounds down

        let spartan = try #require(results.first { $0.id == "337639785" })
        #expect(spartan.eventName == "Fayetteville Spartan Super")
        #expect(spartan.distanceMiles == 8.0)
        #expect(!spartan.isRunning)
    }

    @Test func sortsNewestFirstAndUsesLocalCalendarDay() throws {
        let results = try AthlinksImporter.parse(data: Data(samplePayload.utf8))
        let dates = results.map(\.date)
        #expect(dates == dates.sorted(by: >))

        let components = Calendar.current.dateComponents([.year, .month, .day], from: results[0].date)
        #expect(components.year == 2025)
        #expect(components.month == 11)
        #expect(components.day == 22)
    }

    @Test func skipsEntriesMissingTimeOrDistance() throws {
        let results = try AthlinksImporter.parse(data: Data(samplePayload.utf8))
        #expect(!results.contains { $0.id == "999" })
    }

    @Test func snapsMetersToPresetDistances() {
        #expect(AthlinksImporter.miles(fromMeters: 5000) == 3.1)
        #expect(AthlinksImporter.miles(fromMeters: 8000) == 4.97)
        #expect(AthlinksImporter.miles(fromMeters: 10000) == 6.2)
        #expect(AthlinksImporter.miles(fromMeters: 21082.41) == 13.1)
        #expect(AthlinksImporter.miles(fromMeters: 21100) == 13.1)
        #expect(AthlinksImporter.miles(fromMeters: 42195) == 26.2)
        #expect(AthlinksImporter.miles(fromMeters: 16093.44) == 10.0)
    }

    @Test func normalizesRecurringRaceNames() {
        #expect(AthlinksImporter.eventName(fromRaceName: "2024 Yuengling Shamrock Marathon Weekend") == "Yuengling Shamrock Marathon Weekend")
        #expect(AthlinksImporter.eventName(fromRaceName: "Virginia Spartan Super - Sunday, October 14th 2018") == "Virginia Spartan Super")
        #expect(AthlinksImporter.eventName(fromRaceName: "Toys for Tots 5K 2012") == "Toys for Tots 5K 2012")
        #expect(AthlinksImporter.eventName(fromRaceName: "Carytown 10K") == "Carytown 10K")
    }

    @Test func throwsOnMalformedPayload() {
        #expect(throws: AthlinksImporter.ImportError.self) {
            try AthlinksImporter.parse(data: Data("<html>".utf8))
        }
        #expect(throws: AthlinksImporter.ImportError.self) {
            try AthlinksImporter.parse(data: Data(#"{"Success":false,"Result":null}"#.utf8))
        }
    }

    @Test func throwsWhenProfileHasNoResults() {
        let empty = #"{"Success":true,"Result":{"raceEntries":{"List":[]}}}"#
        #expect(throws: AthlinksImporter.ImportError.self) {
            try AthlinksImporter.parse(data: Data(empty.utf8))
        }
    }

    // Trimmed from a real /athletes/api/{id}/Races response.
    private let samplePayload = """
    {"Success":true,"ErrorMessage":null,"Result":{"raceEntries":{"MasterCount":4,"List":[
      {"EntryID":217546658,"Ticks":1692400,"TicksString":"28:12",
       "Race":{"RaceName":"Petersburg Half Marathon & 5K","RaceDate":"2015-04-18T04:00:00","City":"Petersburg","StateProvAbbrev":"VA",
         "Courses":[{"CoursePattern":"5K","RaceCatDesc":"Running","DistUnit":5000.0,"DistTypeID":6}]}},
      {"EntryID":572448991,"Ticks":6967000,"TicksString":"1:56:07",
       "Race":{"RaceName":"2025 Chartway Norfolk Harbor Half Marathon Weekend","RaceDate":"2025-11-22T05:00:00","City":"Norfolk","StateProvAbbrev":"VA",
         "Courses":[{"CoursePattern":"1/2 Mara","RaceCatDesc":"Running","DistUnit":21082.0,"DistTypeID":6}]}},
      {"EntryID":337639785,"Ticks":10446000,"TicksString":"2:54:06",
       "Race":{"RaceName":"Fayetteville Spartan Super - Saturday, May 12th 2018","RaceDate":"2018-05-12T04:00:00","City":"Spring Lake","StateProvAbbrev":"NC",
         "Courses":[{"CoursePattern":"Spartan Super","RaceCatDesc":"Obstacle","DistUnit":12875.0,"DistTypeID":6}]}},
      {"EntryID":999,"Ticks":0,"TicksString":"",
       "Race":{"RaceName":"Unfinished Race","RaceDate":"2020-01-01T05:00:00","City":"Richmond","StateProvAbbrev":"VA",
         "Courses":[{"CoursePattern":"5K","RaceCatDesc":"Running","DistUnit":5000.0,"DistTypeID":6}]}}
    ]}}}
    """
}
