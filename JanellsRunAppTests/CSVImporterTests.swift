import Testing
import Foundation
@testable import JanellsRunApp

struct CSVImporterTests {
    @Test func parsesGarminCSV() throws {
        let csv = """
        Activity Type,Date,Favorite,Title,Distance,Calories,Time,Avg HR,Max HR
        Running,2026-05-14 07:33:55,false,"Chesterfield County Running","6.00","815","01:02:17","171","187"
        Running,2026-05-12 08:07:26,false,"Chesterfield County Running","4.00","559","00:44:51","162","178"
        """
        let url = try writeTempCSV(csv)
        let runs = try CSVImporter.parse(url: url)

        #expect(runs.count == 2)
        #expect(runs[0].distance == 6.0)
        #expect(runs[0].durationSeconds == 3737) // 1:02:17
        #expect(runs[1].distance == 4.0)
        #expect(runs[1].durationSeconds == 2691) // 44:51
    }

    @Test func filtersNonRunningActivities() throws {
        let csv = """
        Activity Type,Date,Title,Distance,Time
        Running,2026-05-14 07:33:55,"Morning Run","6.00","01:02:17"
        Cycling,2026-05-13 08:00:00,"Bike Ride","20.00","01:30:00"
        Treadmill Running,2026-05-12 06:00:00,"Treadmill","3.00","00:30:00"
        """
        let url = try writeTempCSV(csv)
        let runs = try CSVImporter.parse(url: url)

        #expect(runs.count == 2)
        #expect(runs.allSatisfy { $0.activityType.lowercased().contains("run") })
    }

    @Test func handlesQuotedFieldsWithCommas() throws {
        let csv = """
        Activity Type,Date,Title,Distance,Time
        Running,2026-05-14 07:33:55,"Long, Slow Run","6.00","01:02:17"
        """
        let url = try writeTempCSV(csv)
        let runs = try CSVImporter.parse(url: url)

        #expect(runs.count == 1)
        #expect(runs[0].title == "Long, Slow Run")
    }

    @Test func handlesCommaFormattedNumbers() throws {
        let csv = """
        Activity Type,Date,Title,Distance,Time
        Running,2026-03-07 05:28:34,"Marathon Training","26.77","05:09:21"
        """
        let url = try writeTempCSV(csv)
        let runs = try CSVImporter.parse(url: url)

        #expect(runs.count == 1)
        #expect(runs[0].distance == 26.77)
        #expect(runs[0].durationSeconds == 18561) // 5:09:21
    }

    @Test func parsesMultipleDateFormats() throws {
        let csv1 = "Activity Type,Date,Distance,Time\nRunning,2026-05-14,6.00,01:02:17"
        let csv2 = "Activity Type,Date,Distance,Time\nRunning,05/14/2026,6.00,01:02:17"
        let csv3 = "Activity Type,Date,Distance,Time\nRunning,2026-05-14 07:33:55,6.00,01:02:17"

        for csv in [csv1, csv2, csv3] {
            let url = try writeTempCSV(csv)
            let runs = try CSVImporter.parse(url: url)
            #expect(runs.count == 1, "Failed to parse date in: \(csv)")
        }
    }

    @Test func parsesDurationFormats() throws {
        let csv = """
        Activity Type,Date,Distance,Time
        Running,2026-05-14,6.00,01:02:17
        Running,2026-05-13,3.00,30:00
        Running,2026-05-12,1.00,600
        """
        let url = try writeTempCSV(csv)
        let runs = try CSVImporter.parse(url: url)

        #expect(runs.count == 3)
        #expect(runs[0].durationSeconds == 3737)
        #expect(runs[1].durationSeconds == 1800)
        #expect(runs[2].durationSeconds == 600)
    }

    @Test func stravaHeaders() throws {
        let csv = """
        Activity Type,Activity Date,Activity Name,Moving Time,Distance
        Run,"May 14, 2026, 7:33:55 AM","Morning Run","01:02:17","6.00"
        """
        let url = try writeTempCSV(csv)
        let runs = try CSVImporter.parse(url: url)

        #expect(runs.count == 1)
        #expect(runs[0].distance == 6.0)
        #expect(runs[0].title == "Morning Run")
    }

    @Test func throwsOnEmptyFile() throws {
        let url = try writeTempCSV("")
        #expect(throws: CSVImporter.CSVError.self) {
            try CSVImporter.parse(url: url)
        }
    }

    @Test func throwsOnMissingColumns() throws {
        let csv = "Name,Score\nAlice,100"
        let url = try writeTempCSV(csv)
        #expect(throws: CSVImporter.CSVError.self) {
            try CSVImporter.parse(url: url)
        }
    }

    @Test func throwsWhenNoRunningActivities() throws {
        let csv = """
        Activity Type,Date,Distance,Time
        Cycling,2026-05-14,20.00,01:30:00
        """
        let url = try writeTempCSV(csv)
        #expect(throws: CSVImporter.CSVError.self) {
            try CSVImporter.parse(url: url)
        }
    }

    @Test func returnsSortedByDateDescending() throws {
        let csv = """
        Activity Type,Date,Distance,Time
        Running,2026-01-01,3.00,00:30:00
        Running,2026-06-01,3.00,00:28:00
        Running,2026-03-01,3.00,00:29:00
        """
        let url = try writeTempCSV(csv)
        let runs = try CSVImporter.parse(url: url)

        #expect(runs[0].date > runs[1].date)
        #expect(runs[1].date > runs[2].date)
    }

    private func writeTempCSV(_ content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".csv")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
