import SwiftUI
import SwiftData

struct AddRunView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var preferences
    @Query(sort: \RaceEvent.name) private var events: [RaceEvent]

    @State private var selectedSegment = 0
    @State private var healthKitService = HealthKitService()
    @State private var isRace = true
    @State private var selectedEvent: RaceEvent?
    @State private var isCreatingNewEvent = false
    @State private var newEventName = ""
    @State private var newEventLocation = ""
    @State private var eventSearchText = ""
    @State private var selectedPreset: DistancePreset? = DistancePreset.presets[3]
    @State private var customDistance = ""
    @State private var runDate = Date()
    @State private var hours = ""
    @State private var minutes = ""
    @State private var seconds = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false

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
            VStack(spacing: 0) {
                HeaderView()

                Picker("Input", selection: $selectedSegment) {
                    Text("HealthKit").tag(0)
                    Text("CSV").tag(1)
                    Text("Manual").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Group {
                    switch selectedSegment {
                    case 0:
                        ImportRunsView(healthKitService: healthKitService)
                    case 1:
                        CSVImportView()
                    default:
                        manualEntryForm
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedSegment)
            }
            .dismissKeyboardOnTap()
            .background(Color(.systemBackground))
            .navigationTitle("Log a Run")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") {
                    if isSuccess { resetForm() }
                }
            }
            .sheet(isPresented: $isCreatingNewEvent) {
                newEventSheet
            }
        }
    }

    private var manualEntryForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                raceTrainingToggle
                if isRace { eventSection }
                DistancePicker(selectedPreset: $selectedPreset, customDistance: $customDistance)
                dateSection
                timeSection
                postButton
            }
            .padding()
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
            DatePicker(
                "",
                selection: $runDate,
                in: ...Date(),
                displayedComponents: .date
            )
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

    private var postButton: some View {
        Button {
            saveRun()
        } label: {
            Text("Post Run")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.teal)
                .foregroundStyle(Theme.offWhite)
                .clipShape(Capsule())
        }
        .padding(.top, 8)
        .sensoryFeedback(.success, trigger: isSuccess)
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
            if let matching = DistancePreset.presets.first(where: { abs($0.miles - typicalDistance) < 0.01 }) {
                selectedPreset = matching
                customDistance = ""
            } else {
                selectedPreset = nil
                customDistance = String(format: "%.2f", typicalDistance)
            }
        }
    }

    private func saveRun() {
        if isRace && selectedEvent == nil {
            alertMessage = "Please select or create an event for this race."
            isSuccess = false
            showAlert = true
            return
        }

        guard let distance = resolvedDistance, distance > 0 else {
            alertMessage = "Please enter a distance."
            isSuccess = false
            showAlert = true
            return
        }

        guard totalSeconds >= 60 else {
            alertMessage = "Please enter a valid finish time (at least 1 minute)."
            isSuccess = false
            showAlert = true
            return
        }

        let run = Run(
            distance: distance,
            date: runDate,
            durationSeconds: totalSeconds,
            isRace: isRace,
            event: selectedEvent
        )
        modelContext.insert(run)

        if let event = selectedEvent, event.typicalDistance == nil {
            event.typicalDistance = distance
        }

        let name = isRace ? (selectedEvent?.name ?? "Race") : "Training run"
        alertMessage = "\(name) posted! Great job!"
        isSuccess = true
        showAlert = true
    }

    private func resetForm() {
        isRace = true
        selectedEvent = nil
        eventSearchText = ""
        selectedPreset = DistancePreset.presets[3]
        customDistance = ""
        runDate = Date()
        hours = ""
        minutes = ""
        seconds = ""
    }
}
