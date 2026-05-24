import SwiftUI
import SwiftData

struct DistanceDetailView: View {
    let distance: Double
    @Query(sort: \Run.date) private var allRuns: [Run]
    @Environment(UserPreferences.self) private var preferences

    private var runsAtDistance: [Run] {
        allRuns.filter { $0.isRace && abs($0.distance - distance) < 0.05 }
    }

    private var title: String {
        DistancePreset.label(forMiles: distance) ?? preferences.formatDistance(distance)
    }

    var body: some View {
        List {
            ForEach(Array(runsAtDistance.enumerated()), id: \.element.id) { index, run in
                runRow(run, previousRun: index > 0 ? runsAtDistance[index - 1] : nil)
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runRow(_ run: Run, previousRun: Run?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(run.displayName)
                    .font(.headline)
                Spacer()
                Text(run.formattedTime)
                    .font(.title3.weight(.semibold).monospacedDigit())
            }

            HStack {
                Text(run.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let prev = previousRun {
                    deltaView(current: run.durationSeconds, previous: prev.durationSeconds)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func deltaView(current: Int, previous: Int) -> some View {
        let delta = current - previous
        let isImprovement = delta < 0
        let formatted = TimeFormatter.formatted(abs(delta))

        return HStack(spacing: 2) {
            Image(systemName: isImprovement ? "arrow.down" : "arrow.up")
                .font(.caption)
            Text(formatted)
                .font(.subheadline.monospacedDigit())
        }
        .foregroundStyle(isImprovement ? Theme.improvement : Theme.regression)
    }
}
