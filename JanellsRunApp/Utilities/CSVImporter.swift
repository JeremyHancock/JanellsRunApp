import Foundation

struct CSVRun: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double
    let durationSeconds: Int
    let title: String
    let activityType: String
}

enum CSVImporter {
    enum CSVError: LocalizedError {
        case emptyFile
        case missingColumns
        case noRunningActivities

        var errorDescription: String? {
            switch self {
            case .emptyFile: return "The CSV file is empty."
            case .missingColumns: return "Could not find the required columns (date, distance, time)."
            case .noRunningActivities: return "No running activities found in this file."
            }
        }
    }

    static func parse(url: URL) throws -> [CSVRun] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 2 else { throw CSVError.emptyFile }

        let headers = parseCSVLine(lines[0]).map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard let mapping = detectMapping(headers: headers) else { throw CSVError.missingColumns }

        var runs: [CSVRun] = []
        for i in 1..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(mapping.dateIdx, mapping.distanceIdx, mapping.timeIdx) else { continue }

            let activityType = mapping.activityIdx.map { fields[$0].trimmingCharacters(in: .whitespacesAndNewlines) } ?? "Running"
            guard isRunning(activityType) else { continue }

            let title = mapping.titleIdx.map { fields[$0].trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""

            guard let date = parseDate(fields[mapping.dateIdx].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let distance = parseDistance(fields[mapping.distanceIdx].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let duration = parseDuration(fields[mapping.timeIdx].trimmingCharacters(in: .whitespacesAndNewlines))
            else { continue }

            runs.append(CSVRun(date: date, distance: distance, durationSeconds: duration, title: title, activityType: activityType))
        }

        guard !runs.isEmpty else { throw CSVError.noRunningActivities }
        return runs.sorted { $0.date > $1.date }
    }

    private struct ColumnMapping {
        let dateIdx: Int
        let distanceIdx: Int
        let timeIdx: Int
        let activityIdx: Int?
        let titleIdx: Int?
    }

    private static func detectMapping(headers: [String]) -> ColumnMapping? {
        let dateIdx = headers.firstIndex { ["date", "activity date", "start time", "start date"].contains($0) }
        let distanceIdx = headers.firstIndex { ["distance", "distance (mi)", "distance (miles)"].contains($0) }
        let timeIdx = headers.firstIndex { ["time", "moving time", "duration", "elapsed time"].contains($0) }

        guard let d = dateIdx, let di = distanceIdx, let t = timeIdx else { return nil }

        let activityIdx = headers.firstIndex { ["activity type", "type"].contains($0) }
        let titleIdx = headers.firstIndex { ["title", "name", "activity name"].contains($0) }

        return ColumnMapping(dateIdx: d, distanceIdx: di, timeIdx: t, activityIdx: activityIdx, titleIdx: titleIdx)
    }

    private static func isRunning(_ type: String) -> Bool {
        let lower = type.lowercased()
        return lower.contains("running") || lower.contains("run") || lower == "race"
    }

    private static func parseDate(_ str: String) -> Date? {
        let formatters: [String] = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "MMM d, yyyy, h:mm:ss a",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy",
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for format in formatters {
            df.dateFormat = format
            if let date = df.date(from: str) { return date }
        }
        return nil
    }

    private static func parseDistance(_ str: String) -> Double? {
        let cleaned = str.replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    private static func parseDuration(_ str: String) -> Int? {
        let cleaned = str.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
        let parts = cleaned.split(separator: ":").compactMap { Int($0) }
        if parts.count == 3 {
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        } else if parts.count == 2 {
            return parts[0] * 60 + parts[1]
        } else if let secs = Int(cleaned) {
            return secs
        }
        return nil
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }
}
