import SwiftUI
import SwiftData

struct ImportRunsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var preferences
    @Query private var existingRuns: [Run]
    @Query(sort: \RaceEvent.name) private var events: [RaceEvent]

    let healthKitService: HealthKitService
    @State private var workouts: [HealthKitWorkout] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedWorkout: HealthKitWorkout?

    private var importedIDs: Set<String> {
        Set(existingRuns.compactMap { $0.healthKitID })
    }

    private var unimportedWorkouts: [HealthKitWorkout] {
        workouts.filter { !importedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Checking HealthKit...")
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.secondary)
                    .padding()
            } else if unimportedWorkouts.isEmpty {
                Text("No new workouts to import.")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                HStack {
                    Text("\(unimportedWorkouts.count) new workout\(unimportedWorkouts.count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Button("All Training") {
                        markAllAsTraining()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                List(unimportedWorkouts) { workout in
                    workoutRow(workout)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedWorkout = workout }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await loadWorkouts()
        }
        .refreshable {
            await loadWorkouts()
        }
        .sheet(item: $selectedWorkout) { workout in
            EnrichWorkoutSheet(
                workout: workout,
                events: events,
                onSave: { run in
                    modelContext.insert(run)
                    selectedWorkout = nil
                }
            )
        }
    }

    private func workoutRow(_ workout: HealthKitWorkout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline.weight(.medium))
                Text(preferences.formatDistance(workout.distance))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(TimeFormatter.formatted(workout.durationSeconds))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        do {
            try await healthKitService.requestAuthorization()
            workouts = try await healthKitService.fetchRunningWorkouts()
        } catch {
            errorMessage = "Could not load workouts from HealthKit."
        }
        isLoading = false
    }

    private func markAllAsTraining() {
        for workout in unimportedWorkouts {
            let run = Run(
                distance: workout.distance,
                date: workout.date,
                durationSeconds: workout.durationSeconds,
                isRace: false,
                healthKitID: workout.id
            )
            modelContext.insert(run)
        }
    }
}

struct EnrichWorkoutSheet: View {
    let workout: HealthKitWorkout
    let events: [RaceEvent]
    let onSave: (Run) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var preferences
    @State private var isRace = true
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
                    LabeledContent("Date", value: workout.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    LabeledContent("Distance", value: preferences.formatDistance(workout.distance))
                    LabeledContent("Time", value: TimeFormatter.formatted(workout.durationSeconds))
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
            .navigationTitle("Tag Workout")
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
                                    typicalDistance: workout.distance
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
            distance: workout.distance,
            date: workout.date,
            durationSeconds: workout.durationSeconds,
            isRace: isRace,
            event: isRace ? selectedEvent : nil,
            healthKitID: workout.id
        )
        onSave(run)
    }
}
