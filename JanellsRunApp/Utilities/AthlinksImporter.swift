import Foundation

/// One claimed race result from an Athlinks athlete profile.
struct AthlinksResult: Identifiable, Hashable {
    /// Athlinks EntryID. Stored on `Run.athlinksResultID` so re-syncs skip it.
    let id: String
    let raceName: String
    let eventName: String
    let date: Date
    let location: String?
    let distanceMiles: Double
    let durationSeconds: Int
    let coursePattern: String
    let category: String

    /// Obstacle races (Spartan, Warrior Dash) are timed very differently from
    /// road races, so they are shown but left unselected by default.
    var isRunning: Bool {
        category.localizedCaseInsensitiveContains("run")
    }
}

enum AthlinksImporter {
    enum ImportError: LocalizedError {
        case invalidAthleteID
        case badResponse
        case noResults

        var errorDescription: String? {
            switch self {
            case .invalidAthleteID:
                return "Enter an Athlinks profile link or athlete ID."
            case .badResponse:
                return "Athlinks returned something unexpected. Try again later."
            case .noResults:
                return "No claimed results were found on this Athlinks profile."
            }
        }
    }

    /// Accepts a bare numeric ID or any athlinks.com profile URL, e.g.
    /// `https://www.athlinks.com/athletes/410409327/results`.
    static func athleteID(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.allSatisfy(\.isNumber) { return trimmed }

        let pattern = #"athletes/(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let range = Range(match.range(at: 1), in: trimmed)
        else { return nil }
        return String(trimmed[range])
    }

    /// Undocumented endpoint the athlinks.com results page itself reads from.
    static func resultsURL(athleteID: String) -> URL {
        URL(string: "https://alaska.athlinks.com/athletes/api/\(athleteID)/Races")!
    }

    static func parse(data: Data) throws -> [AthlinksResult] {
        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            throw ImportError.badResponse
        }
        guard payload.success, let entries = payload.result?.raceEntries?.list else {
            throw ImportError.badResponse
        }

        let results = entries.compactMap(result(from:))
        guard !results.isEmpty else { throw ImportError.noResults }
        return results.sorted { $0.date > $1.date }
    }

    // MARK: - Mapping

    private static func result(from entry: Entry) -> AthlinksResult? {
        guard let race = entry.race,
              let name = race.raceName, !name.isEmpty,
              let date = parseDate(race.raceDate),
              let course = race.courses?.first,
              let meters = course.distUnit, meters > 0,
              let ticks = entry.ticks, ticks > 0
        else { return nil }

        return AthlinksResult(
            id: String(entry.entryID),
            raceName: name,
            eventName: eventName(fromRaceName: name),
            date: date,
            location: location(city: race.city, state: race.stateProvAbbrev),
            distanceMiles: miles(fromMeters: meters),
            durationSeconds: Int((Double(ticks) / 1000).rounded()),
            coursePattern: course.coursePattern ?? "",
            category: course.raceCatDesc ?? ""
        )
    }

    /// Athlinks stores course length in meters. Snap to the app's presets so
    /// a 5K imports as 3.1 mi (not 3.107) and groups with existing PRs.
    static func miles(fromMeters meters: Double) -> Double {
        let raw = meters / 1609.344
        if let preset = DistancePreset.matchingPreset(forMiles: raw) {
            return preset.miles
        }
        return (raw * 100).rounded() / 100
    }

    /// Strips the year Athlinks prefixes onto recurring races
    /// ("2024 Norfolk Harbor Half") and the "- Saturday, May 12th 2018" suffix
    /// on obstacle events, so repeat races group under one RaceEvent.
    static func eventName(fromRaceName name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespaces)
        cleaned = cleaned.replacingOccurrences(
            of: #"^(19|20)\d{2}\s+"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(
            of: #"\s+-\s+(Mon|Tues|Wednes|Thurs|Fri|Satur|Sun)day,.*$"#,
            with: "", options: [.regularExpression, .caseInsensitive])
        return cleaned.isEmpty ? name : cleaned
    }

    private static func location(city: String?, state: String?) -> String? {
        let parts = [city, state]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// RaceDate arrives as "2026-03-07T05:00:00" with no zone. Only the
    /// calendar day is meaningful, so parse it as local midnight.
    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, raw.count >= 10 else { return nil }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: String(raw.prefix(10)))
    }

    // MARK: - Wire format

    private struct Payload: Decodable {
        let success: Bool
        let result: ResultBody?

        enum CodingKeys: String, CodingKey {
            case success = "Success"
            case result = "Result"
        }
    }

    private struct ResultBody: Decodable {
        let raceEntries: RaceEntries?
    }

    private struct RaceEntries: Decodable {
        let list: [Entry]?

        enum CodingKeys: String, CodingKey {
            case list = "List"
        }
    }

    private struct Entry: Decodable {
        let entryID: Int
        let ticks: Int?
        let race: Race?

        enum CodingKeys: String, CodingKey {
            case entryID = "EntryID"
            case ticks = "Ticks"
            case race = "Race"
        }
    }

    private struct Race: Decodable {
        let raceName: String?
        let raceDate: String?
        let city: String?
        let stateProvAbbrev: String?
        let courses: [Course]?

        enum CodingKeys: String, CodingKey {
            case raceName = "RaceName"
            case raceDate = "RaceDate"
            case city = "City"
            case stateProvAbbrev = "StateProvAbbrev"
            case courses = "Courses"
        }
    }

    private struct Course: Decodable {
        let coursePattern: String?
        let raceCatDesc: String?
        let distUnit: Double?

        enum CodingKeys: String, CodingKey {
            case coursePattern = "CoursePattern"
            case raceCatDesc = "RaceCatDesc"
            case distUnit = "DistUnit"
        }
    }
}
