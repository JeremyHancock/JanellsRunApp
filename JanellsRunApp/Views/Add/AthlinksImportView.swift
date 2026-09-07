import SwiftUI
import SwiftData

struct AthlinksImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var preferences
    @Query private var existingRuns: [Run]
    @Query(sort: \RaceEvent.name) private var events: [RaceEvent]

    @State private var athleteInput = ""
    @State private var results: [AthlinksResult] = []
    @State private var selectedIDs: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var importedCount = 0
    @State private var hasLoaded = false

    private var importedIDs: Set<String> {
        Set(existingRuns.compactMap { $0.athlinksResultID })
    }

    private var unimportedResults: [AthlinksResult] {
        results.filter { result in
            guard !importedIDs.contains(result.id) else { return false }
            // Fallback for races that were entered by hand before this importer existed.
            return !existingRuns.contains { existing in
                DuplicateChecker.isSameRun(
                    as: existing, date: result.date,
                    distance: result.distanceMiles, durationSeconds: result.durationSeconds)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading Athlinks results...")
                    .padding()
                Spacer()
            } else if !hasLoaded || errorMessage != nil {
                AthlinksLookupForm(
                    athleteInput: $athleteInput,
                    errorMessage: errorMessage,
                    onLoad: { Task { await loadResults() } })
            } else if unimportedResults.isEmpty {
                allImportedState
            } else {
                resultList
            }
        }
        .onAppear {
            if athleteInput.isEmpty, let saved = preferences.athlinksAthleteID {
                athleteInput = saved
            }
        }
    }

    private var allImportedState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.teal)
            Text(importedCount > 0
                 ? "Imported \(importedCount) race\(importedCount == 1 ? "" : "s") from Athlinks!"
                 : "All Athlinks results are already in the app.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Check Again") {
                Task { await loadResults() }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.teal)
            Button("Use a Different Profile") {
                hasLoaded = false
                results = []
                importedCount = 0
            }
            .font(.subheadline)
            .foregroundStyle(Theme.teal)
            Spacer()
        }
    }

    private var resultList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(unimportedResults.count) new result\(unimportedResults.count == 1 ? "" : "s")")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button(importButtonTitle) {
                    importSelected()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.teal)
                .disabled(selectedIDs.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            List(unimportedResults) { result in
                AthlinksResultRow(result: result, isSelected: selectedIDs.contains(result.id))
                    .contentShape(Rectangle())
                    .onTapGesture { toggle(result) }
            }
            .listStyle(.plain)
        }
    }

    private var importButtonTitle: String {
        let count = selectedIDs.intersection(unimportedResults.map(\.id)).count
        return "Import \(count)"
    }

    private func toggle(_ result: AthlinksResult) {
        if selectedIDs.contains(result.id) {
            selectedIDs.remove(result.id)
        } else {
            selectedIDs.insert(result.id)
        }
    }

    private func loadResults() async {
        guard let athleteID = AthlinksImporter.athleteID(from: athleteInput) else {
            errorMessage = AthlinksImporter.ImportError.invalidAthleteID.localizedDescription
            return
        }
        isLoading = true
        errorMessage = nil
        importedCount = 0
        do {
            results = try await AthlinksService.fetchResults(athleteID: athleteID)
            preferences.athlinksAthleteID = athleteID
            selectedIDs = Set(unimportedResults.filter(\.isRunning).map(\.id))
            hasLoaded = true
        } catch let error as AthlinksImporter.ImportError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Could not reach Athlinks. Check your connection and try again."
        }
        isLoading = false
    }

    private func importSelected() {
        var eventsByName: [String: RaceEvent] = [:]
        for event in events {
            eventsByName[event.name.lowercased()] = event
        }

        for result in unimportedResults where selectedIDs.contains(result.id) {
            let key = result.eventName.lowercased()
            let event: RaceEvent
            if let existing = eventsByName[key] {
                event = existing
            } else {
                event = RaceEvent(
                    name: result.eventName,
                    location: result.location,
                    typicalDistance: result.distanceMiles)
                modelContext.insert(event)
                eventsByName[key] = event
            }

            let run = Run(
                distance: result.distanceMiles,
                date: result.date,
                durationSeconds: result.durationSeconds,
                isRace: true,
                event: event)
            run.athlinksResultID = result.id
            modelContext.insert(run)
            importedCount += 1
        }
        selectedIDs = []
    }
}

private struct AthlinksLookupForm: View {
    @Binding var athleteInput: String
    let errorMessage: String?
    let onLoad: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Import race results from Athlinks")
                .foregroundStyle(.secondary)
            Text("Paste your Athlinks profile link or athlete ID. Only results claimed on your profile will appear.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            TextField("athlinks.com/athletes/12345", text: $athleteInput)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(onLoad)
                .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onLoad) {
                Text("Load Results")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Theme.teal)
                    .foregroundStyle(Theme.offWhite)
                    .clipShape(Capsule())
            }
            .disabled(athleteInput.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
        }
    }
}

private struct AthlinksResultRow: View {
    @Environment(UserPreferences.self) private var preferences
    let result: AthlinksResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Theme.teal : Color.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.eventName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !result.isRunning {
                    Text(result.category)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text(TimeFormatter.formatted(result.durationSeconds))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        var parts = [
            result.date.formatted(.dateTime.month(.abbreviated).day().year()),
            preferences.formatDistance(result.distanceMiles),
        ]
        if let location = result.location { parts.append(location) }
        return parts.joined(separator: " · ")
    }
}
