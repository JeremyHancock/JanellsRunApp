import SwiftUI

struct NotesField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            TextField("How did it go? (optional)", text: $text, axis: .vertical)
                .lineLimit(2...6)
                .padding(10)
                .background(Theme.tableGray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    /// What to store for the typed text: trimmed, or nil when blank.
    static func storedValue(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
