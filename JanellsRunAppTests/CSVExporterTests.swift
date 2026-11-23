import Foundation
import Testing
@testable import JanellsRunApp

struct CSVExporterTests {
    private func date(_ string: String) -> Date {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: string)!
    }

    @Test func writesOneRowPerRunNewestFirst() {
        let event = RaceEvent(name: "Monument Avenue 10K", location: "Richmond, VA")
        let race = Run(distance: 6.2, date: date("2026-04-18 08:00:00"), durationSeconds: 3505, isRace: true, event: event, notes: "Windy, felt strong")
        let training = Run(distance: 4.0, date: date("2026-05-12 07:00:00"), durationSeconds: 2691, isRace: false)

        let lines = CSVExporter.csv(for: [race, training]).split(separator: "\n").map(String.init)

        #expect(lines.count == 3)
        #expect(lines[0] == CSVExporter.header)
        #expect(lines[1] == "Running,2026-05-12 07:00:00,Training,4.00,00:44:51,No,,,")
        #expect(lines[2] == "Running,2026-04-18 08:00:00,Monument Avenue 10K,6.20,00:58:25,Yes,Monument Avenue 10K,\"Richmond, VA\",\"Windy, felt strong\"")
    }

    @Test func fieldQuotingKeepsEachRunOnOneLine() {
        #expect(CSVExporter.field("plain") == "plain")
        #expect(CSVExporter.field("a, b") == "\"a, b\"")
        #expect(CSVExporter.field("said \"go\"") == "\"said \"\"go\"\"\"")
        #expect(CSVExporter.field("line one\nline two") == "line one line two")
    }

    @Test func exportReadsBackThroughTheImporter() throws {
        let runs = [
            Run(distance: 13.1, date: date("2025-11-22 07:30:00"), durationSeconds: 6967, isRace: true, notes: "PR, cold start"),
            Run(distance: 3.12, date: date("2026-01-03 09:15:00"), durationSeconds: 1500, isRace: false),
        ]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".csv")
        try CSVExporter.csv(for: runs).write(to: url, atomically: true, encoding: .utf8)

        let imported = try CSVImporter.parse(url: url)

        #expect(imported.map(\.distance) == [3.12, 13.1])
        #expect(imported.map(\.durationSeconds) == [1500, 6967])
        #expect(imported.map(\.date) == [date("2026-01-03 09:15:00"), date("2025-11-22 07:30:00")])
    }
}
