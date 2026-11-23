import Foundation

enum EventSearch {
    /// The name to offer as a new event for what's typed in an event search
    /// field: the trimmed text, or nil when it's empty or an event with that
    /// name already exists.
    static func newEventName(forSearch text: String, existingNames: [String]) -> String? {
        let name = text.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        let exists = existingNames.contains { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }
        return exists ? nil : name
    }
}
