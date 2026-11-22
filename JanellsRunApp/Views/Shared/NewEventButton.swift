import SwiftUI

/// Sits under an event search field. Once the search text isn't an existing
/// event it offers to create one with that name, so searching and creating
/// read as one flow.
struct NewEventButton: View {
    let searchText: String
    let existingNames: [String]
    /// Called with the name to prefill, empty when nothing usable was typed.
    let action: (String) -> Void

    private var suggestedName: String? {
        EventSearch.newEventName(forSearch: searchText, existingNames: existingNames)
    }

    var body: some View {
        Button {
            action(suggestedName ?? "")
        } label: {
            if let suggestedName {
                Label("Create “\(suggestedName)”", systemImage: "plus.circle")
            } else {
                Label("New Event", systemImage: "plus.circle")
            }
        }
    }
}
