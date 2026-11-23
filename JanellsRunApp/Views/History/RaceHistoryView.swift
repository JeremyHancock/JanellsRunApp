import SwiftUI
import SwiftData

struct RaceHistoryView: View {
    @Query(sort: \RaceEvent.name) private var events: [RaceEvent]
    @Environment(UserPreferences.self) private var preferences

    private var eventsWithRuns: [RaceEvent] {
        events.filter { !($0.runs ?? []).isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()

                if eventsWithRuns.isEmpty {
                    Spacer()
                    Text("Race events will appear here after you log your first race.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    List(eventsWithRuns) { event in
                        NavigationLink(destination: RaceEventDetailView(event: event)) {
                            eventRow(event)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Race History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func eventRow(_ event: RaceEvent) -> some View {
        let runs = event.runs ?? []
        let bestRun = PersonalRecords.eventBest(in: runs, typicalDistance: event.typicalDistance)
        let yearCount = Set(runs.map { $0.year }).count

        return VStack(alignment: .leading, spacing: 4) {
            Text(event.name)
                .font(.headline)
            HStack {
                if let location = event.location {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(yearCount) \(yearCount == 1 ? "year" : "years")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let best = bestRun {
                Text(prText(best, showDistance: PersonalRecords.hasMultipleDistances(runs)))
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
            }
        }
        .padding(.vertical, 2)
    }

    /// Names the distance when the event has been run at more than one.
    private func prText(_ best: Run, showDistance: Bool) -> String {
        guard showDistance else { return "PR: \(best.formattedTime)" }
        let distance = DistancePreset.label(forMiles: best.distance) ?? preferences.formatDistance(best.distance)
        return "PR: \(best.formattedTime) (\(distance))"
    }
}
