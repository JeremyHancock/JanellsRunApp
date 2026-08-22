import SwiftUI

struct EditRaceEventSheet: View {
    let event: RaceEvent

    @Environment(\.dismiss) private var dismiss
    @Environment(UserPreferences.self) private var preferences

    @State private var name: String
    @State private var location: String
    @State private var distanceText = ""
    @State private var initialDistanceText = ""

    init(event: RaceEvent) {
        self.event = event
        _name = State(initialValue: event.name)
        _location = State(initialValue: event.location ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Event Name", text: $name)
                TextField("Location (optional)", text: $location)
                TextField("Typical Distance in \(preferences.distanceUnit.abbreviation) (optional)", text: $distanceText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let miles = event.typicalDistance {
                    distanceText = preferences.formatNumber(preferences.displayDistance(miles))
                }
                initialDistanceText = distanceText
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        event.name = name.trimmingCharacters(in: .whitespaces)
        let trimmedLocation = location.trimmingCharacters(in: .whitespaces)
        event.location = trimmedLocation.isEmpty ? nil : trimmedLocation

        // Only rewrite the distance if the field was changed, so an untouched
        // value doesn't drift through unit round-tripping.
        if distanceText != initialDistanceText {
            let trimmedDistance = distanceText.trimmingCharacters(in: .whitespaces)
            if let value = Double(trimmedDistance), value > 0 {
                event.typicalDistance = value * preferences.distanceUnit.conversionToMiles
            } else if trimmedDistance.isEmpty {
                event.typicalDistance = nil
            }
        }

        dismiss()
    }
}
