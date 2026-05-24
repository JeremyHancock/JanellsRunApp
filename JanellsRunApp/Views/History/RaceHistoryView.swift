import SwiftUI
import SwiftData

struct RaceHistoryView: View {
    @Query(sort: \RaceEvent.name) private var events: [RaceEvent]

    private var eventsWithRuns: [RaceEvent] {
        events.filter { !$0.runs.isEmpty }
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
        let sortedRuns = event.runs.sorted { $0.date < $1.date }
        let bestRun = sortedRuns.min { $0.durationSeconds < $1.durationSeconds }
        let yearCount = Set(sortedRuns.map { $0.year }).count

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
                Text("PR: \(best.formattedTime)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
            }
        }
        .padding(.vertical, 2)
    }
}
