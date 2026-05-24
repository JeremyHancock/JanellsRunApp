import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var existingRuns: [Run]
    @Query(sort: \RaceEvent.name) private var events: [RaceEvent]

    @State private var showFilePicker = false
    @State private var parsedRuns: [CSVRun] = []
    @State private var errorMessage: String?
    @State private var selectedRun: CSVRun?
    @State private var importedCount = 0
    @Environment(UserPreferences.self) private var preferences
    @State private var csvUnit: CSVDistanceUnit = .miles

    enum CSVDistanceUnit: String, CaseIterable {
        case miles = "Miles"
        case kilometers = "Kilometers"

        var conversionToMiles: Double {
            switch self {
            case .miles: return 1.0
            case .kilometers: return 0.621371
            }
        }
    }

    private func convertedDistance(_ d: Double) -> Double {
        d * csvUnit.conversionToMiles
    }

    private var unimportedRuns: [CSVRun] {
        parsedRuns.filter { csv in
            let miles = convertedDistance(csv.distance)
            return !existingRuns.contains { existing in
                abs(existing.date.timeIntervalSince(csv.date)) < 60
                && abs(existing.distance - miles) < 0.01
                && abs(existing.durationSeconds - csv.durationSeconds) < 2
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if parsedRuns.isEmpty && errorMessage == nil {
                emptyState
            } else if let error = errorMessage {
                errorState(error)
            } else if unimportedRuns.isEmpty {
                allImportedState
            } else {
                runList
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [UTType.commaSeparatedText]) { result in
            handleFile(result)
        }
        .sheet(item: $selectedRun) { run in
            CSVEnrichSheet(csvRun: run, distanceInMiles: convertedDistance(run.distance), events: events) { newRun in
                modelContext.insert(newRun)
                importedCount += 1
                selectedRun = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Import runs from a CSV file")
                .foregroundStyle(.secondary)
            Text("Supports Garmin, Strava, and COROS exports")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button {
                showFilePicker = true
            } label: {
                Text("Select CSV File")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Theme.teal)
                    .foregroundStyle(Theme.offWhite)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                errorMessage = nil
                showFilePicker = true
            } label: {
                Text("Try Another File")
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
            }
            Spacer()
        }
    }

    private var allImportedState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.teal)
            Text("All \(importedCount) runs imported!")
                .foregroundStyle(.secondary)
            Button {
                parsedRuns = []
                importedCount = 0
                showFilePicker = true
            } label: {
                Text("Import Another File")
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
            }
            Spacer()
        }
    }

    private var runList: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Picker("CSV Unit", selection: $csvUnit) {
                    ForEach(CSVDistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("\(unimportedRuns.count) run\(unimportedRuns.count == 1 ? "" : "s") found")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Button("All Training") {
                        importAllAsTraining()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            List(unimportedRuns) { run in
                csvRunRow(run)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedRun = run }
            }
            .listStyle(.plain)
        }
    }

    private func csvRunRow(_ run: CSVRun) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(run.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline.weight(.medium))
                Text(preferences.formatDistance(convertedDistance(run.distance)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(TimeFormatter.formatted(run.durationSeconds))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func handleFile(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Could not access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                parsedRuns = try CSVImporter.parse(url: url)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure:
            errorMessage = "Could not open the file."
        }
    }

    private func importAllAsTraining() {
        for run in unimportedRuns {
            let newRun = Run(
                distance: convertedDistance(run.distance),
                date: run.date,
                durationSeconds: run.durationSeconds,
                isRace: false
            )
            modelContext.insert(newRun)
            importedCount += 1
        }
    }
}

struct CSVEnrichSheet: View {
    let csvRun: CSVRun
    let distanceInMiles: Double
    let events: [RaceEvent]
    let onSave: (Run) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var preferences
    @State private var isRace = false
    @State private var selectedEvent: RaceEvent?
    @State private var isCreatingNewEvent = false
    @State private var newEventName = ""
    @State private var newEventLocation = ""
    @State private var eventSearchText = ""

    private var filteredEvents: [RaceEvent] {
        if eventSearchText.isEmpty { return events }
        return events.filter { $0.name.localizedCaseInsensitiveContains(eventSearchText) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Date", value: csvRun.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    LabeledContent("Distance", value: preferences.formatDistance(distanceInMiles))
                    LabeledContent("Time", value: TimeFormatter.formatted(csvRun.durationSeconds))
                    if !csvRun.title.isEmpty {
                        LabeledContent("Title", value: csvRun.title)
                    }
                }

                Section {
                    Toggle("Race", isOn: $isRace)
                        .tint(Theme.teal)
                }

                if isRace {
                    Section("Event") {
                        TextField("Search events...", text: $eventSearchText)

                        ForEach(filteredEvents) { event in
                            Button {
                                selectedEvent = event
                                eventSearchText = ""
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(event.name)
                                            .foregroundStyle(.primary)
                                        if let location = event.location {
                                            Text(location)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedEvent?.id == event.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.teal)
                                    }
                                }
                            }
                        }

                        Button {
                            isCreatingNewEvent = true
                        } label: {
                            Label("New Event", systemImage: "plus.circle")
                        }
                    }
                }
            }
            .navigationTitle("Tag Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isRace && selectedEvent == nil)
                }
            }
            .sheet(isPresented: $isCreatingNewEvent) {
                NavigationStack {
                    Form {
                        TextField("Event Name", text: $newEventName)
                        TextField("Location (optional)", text: $newEventLocation)
                    }
                    .navigationTitle("New Event")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isCreatingNewEvent = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                let event = RaceEvent(
                                    name: newEventName.trimmingCharacters(in: .whitespaces),
                                    location: newEventLocation.isEmpty ? nil : newEventLocation.trimmingCharacters(in: .whitespaces),
                                    typicalDistance: distanceInMiles
                                )
                                modelContext.insert(event)
                                selectedEvent = event
                                newEventName = ""
                                newEventLocation = ""
                                isCreatingNewEvent = false
                            }
                            .disabled(newEventName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func save() {
        let run = Run(
            distance: distanceInMiles,
            date: csvRun.date,
            durationSeconds: csvRun.durationSeconds,
            isRace: isRace,
            event: isRace ? selectedEvent : nil
        )
        onSave(run)
    }
}
