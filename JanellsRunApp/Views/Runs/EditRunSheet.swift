import SwiftUI
import SwiftData

struct EditRunSheet: View {
    @Bindable var run: Run
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var preferences
    @Query(sort: \RaceEvent.name) private var events: [RaceEvent]

    @State private var isRace: Bool
    @State private var selectedEvent: RaceEvent?
    @State private var selectedPreset: DistancePreset?
    @State private var customDistance: String
    @State private var runDate: Date
    @State private var hours: String
    @State private var minutes: String
    @State private var seconds: String
    @State private var eventSearchText = ""
    @State private var isCreatingNewEvent = false
    @State private var newEventName = ""
    @State private var newEventLocation = ""

    init(run: Run) {
        self.run = run
        _isRace = State(initialValue: run.isRace)
        _selectedEvent = State(initialValue: run.event)
        _runDate = State(initialValue: run.date)

        let h = run.durationSeconds / 3600
        let m = (run.durationSeconds % 3600) / 60
        let s = run.durationSeconds % 60
        _hours = State(initialValue: h > 0 ? "\(h)" : "")
        _minutes = State(initialValue: m > 0 || h > 0 ? "\(m)" : "")
        _seconds = State(initialValue: "\(s)")

        if let preset = DistancePreset.matchingPreset(forMiles: run.distance) {
            _selectedPreset = State(initialValue: preset)
            _customDistance = State(initialValue: "")
        } else {
            _selectedPreset = State(initialValue: nil)
            _customDistance = State(initialValue: String(format: "%.2f", run.distance))
        }
    }

    private var filteredEvents: [RaceEvent] {
        if eventSearchText.isEmpty { return events }
        return events.filter { $0.name.localizedCaseInsensitiveContains(eventSearchText) }
    }

    private var resolvedDistance: Double? {
        if let preset = selectedPreset {
            return preset.miles
        }
        guard let value = Double(customDistance) else { return nil }
        return value * preferences.distanceUnit.conversionToMiles
    }

    private var totalSeconds: Int {
        TimeFormatter.totalSeconds(
            hours: Int(hours) ?? 0,
            minutes: Int(minutes) ?? 0,
            seconds: Int(seconds) ?? 0
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    raceTrainingToggle
                    if isRace { eventSection }
                    DistancePicker(selectedPreset: $selectedPreset, customDistance: $customDistance)
                    dateSection
                    timeSection
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Edit Run")
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
                newEventSheet
            }
        }
    }

    private var raceTrainingToggle: some View {
        HStack {
            Text("Training")
                .foregroundStyle(!isRace ? .primary : .secondary)
            Toggle("", isOn: $isRace)
                .toggleStyle(SwitchToggleStyle(tint: Theme.teal))
                .labelsHidden()
            Text("Race")
                .foregroundStyle(isRace ? .primary : .secondary)
        }
        .onChange(of: isRace) {
            if !isRace {
                selectedEvent = nil
                eventSearchText = ""
            }
        }
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Event")
                .font(.headline)

            TextField("Search events...", text: $eventSearchText)
                .textFieldStyle(.roundedBorder)

            if !filteredEvents.isEmpty && !eventSearchText.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredEvents) { event in
                            Button {
                                selectEvent(event)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.name)
                                        .foregroundStyle(.primary)
                                    if let location = event.location {
                                        Text(location)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(Theme.tableGray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let selected = selectedEvent {
                HStack {
                    Text(selected.name)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.teal)
                        .foregroundStyle(Theme.offWhite)
                        .clipShape(Capsule())
                    Button {
                        selectedEvent = nil
                        eventSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                isCreatingNewEvent = true
            } label: {
                Label("New Event", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.headline)
            DatePicker("", selection: $runDate, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Finish Time")
                .font(.headline)
            HStack(spacing: 4) {
                timeField("H", text: $hours)
                Text(":").font(.title2.weight(.bold))
                timeField("M", text: $minutes)
                Text(":").font(.title2.weight(.bold))
                timeField("S", text: $seconds)
            }
        }
    }

    private func timeField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 50, height: 44)
            .background(Theme.tableGray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onChange(of: text.wrappedValue) { _, newValue in
                if newValue.count > 2 {
                    text.wrappedValue = String(newValue.prefix(2))
                }
            }
    }

    private var newEventSheet: some View {
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
                            location: newEventLocation.isEmpty ? nil : newEventLocation.trimmingCharacters(in: .whitespaces)
                        )
                        modelContext.insert(event)
                        selectEvent(event)
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

    private func selectEvent(_ event: RaceEvent) {
        selectedEvent = event
        eventSearchText = ""
        if let typicalDistance = event.typicalDistance {
            if let matching = DistancePreset.presets.first(where: { abs($0.miles - typicalDistance) < 0.05 }) {
                selectedPreset = matching
                customDistance = ""
            } else {
                selectedPreset = nil
                customDistance = String(format: "%.2f", typicalDistance)
            }
        }
    }

    private func save() {
        guard let distance = resolvedDistance, distance > 0 else { return }
        guard totalSeconds >= 60 else { return }

        run.distance = distance
        run.date = runDate
        run.durationSeconds = totalSeconds
        run.isRace = isRace
        run.event = isRace ? selectedEvent : nil

        if isRace, let event = selectedEvent, event.typicalDistance == nil {
            event.typicalDistance = distance
        }

        dismiss()
    }
}
