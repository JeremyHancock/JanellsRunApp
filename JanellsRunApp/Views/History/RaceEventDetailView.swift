import SwiftUI

struct RaceEventDetailView: View {
    let event: RaceEvent
    @Environment(UserPreferences.self) private var preferences

    private var sortedRuns: [Run] {
        event.runs.sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            ForEach(Array(sortedRuns.enumerated()), id: \.element.id) { index, run in
                runRow(run, previousRun: index > 0 ? sortedRuns[index - 1] : nil)
            }
        }
        .listStyle(.plain)
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runRow(_ run: Run, previousRun: Run?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(run.year))
                    .font(.headline)
                Spacer()
                Text(run.formattedTime)
                    .font(.title3.weight(.semibold).monospacedDigit())
            }

            HStack {
                Text(preferences.formatDistance(run.distance))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let prev = previousRun {
                    deltaView(current: run.durationSeconds, previous: prev.durationSeconds)
                }
            }

            Text(run.date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func deltaView(current: Int, previous: Int) -> some View {
        let delta = current - previous
        let isImprovement = delta < 0
        let absDelta = abs(delta)
        let formatted = TimeFormatter.formatted(absDelta)

        return HStack(spacing: 2) {
            Image(systemName: isImprovement ? "arrow.down" : "arrow.up")
                .font(.caption)
            Text(formatted)
                .font(.subheadline.monospacedDigit())
        }
        .foregroundStyle(isImprovement ? Theme.improvement : Theme.regression)
    }
}
