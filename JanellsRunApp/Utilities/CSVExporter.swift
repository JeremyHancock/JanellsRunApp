import CoreTransferable
import Foundation
import UniformTypeIdentifiers

enum CSVExporter {
    static let header = "Activity Type,Date,Title,Distance (mi),Time,Race,Event,Location,Notes"

    /// Every run, newest first, in a layout `CSVImporter` can read back.
    /// Distances are in miles whatever the display unit is.
    static func csv(for runs: [Run]) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let rows = runs.sorted { $0.date > $1.date }.map { run in
            [
                "Running",
                df.string(from: run.date),
                run.displayName,
                String(format: "%.2f", run.distance),
                TimeFormatter.formatted(run.durationSeconds),
                run.isRace ? "Yes" : "No",
                run.event?.name ?? "",
                run.event?.location ?? "",
                run.notes ?? "",
            ]
            .map(field)
            .joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    /// Quotes a value when it needs it. Line breaks become spaces because the
    /// importer reads one run per line.
    static func field(_ value: String) -> String {
        let oneLine = value.components(separatedBy: .newlines).joined(separator: " ")
        guard oneLine.contains(where: { $0 == "," || $0 == "\"" }) else { return oneLine }
        return "\"" + oneLine.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// The export as something the share sheet can save or send as a file.
struct RunsCSVFile: Transferable {
    let csv: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.csv.utf8)
        }
        .suggestedFileName("janells-runs.csv")
    }
}
