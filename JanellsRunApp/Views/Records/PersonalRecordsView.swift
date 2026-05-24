import SwiftUI
import SwiftData

struct PersonalRecordsView: View {
    @Query(sort: \Run.date, order: .reverse) private var allRuns: [Run]
    @Environment(UserPreferences.self) private var preferences

    @State private var selectedYear: Int?

    private var yearOptions: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed()
    }

    private var races: [Run] {
        var filtered = allRuns.filter { $0.isRace }
        if let year = selectedYear {
            filtered = filtered.filter { $0.year == year }
        }
        return filtered
    }

    private var personalRecords: [Run] {
        var bestByDistance: [String: Run] = [:]
        for run in races {
            let key = String(format: "%.2f", run.distance)
            if let existing = bestByDistance[key] {
                if run.durationSeconds < existing.durationSeconds {
                    bestByDistance[key] = run
                }
            } else {
                bestByDistance[key] = run
            }
        }
        return bestByDistance.values.sorted { $0.distance > $1.distance }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()

                yearPicker

                if personalRecords.isEmpty {
                    Spacer()
                    if selectedYear != nil {
                        Text("No races logged for this year.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Your PRs are gonna look AMAZING here")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    Spacer()
                } else {
                    List(personalRecords) { pr in
                        prRow(pr)
                    }
                    .listStyle(.plain)
                    .animation(.default, value: personalRecords.map(\.id))
                }
            }
            .navigationTitle("Personal Records")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var yearPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                yearChip("All Time", isSelected: selectedYear == nil) {
                    selectedYear = nil
                }
                ForEach(yearOptions, id: \.self) { year in
                    yearChip(String(year), isSelected: selectedYear == year) {
                        selectedYear = year
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func yearChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.teal : Theme.tableGray)
                .foregroundStyle(isSelected ? Theme.offWhite : .primary)
                .clipShape(Capsule())
        }
    }

    private func prRow(_ run: Run) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(run.formattedTime)
                    .font(.title2.weight(.bold).monospacedDigit())
                Spacer()
                Text(distanceLabel(run.distance))
                    .font(.headline)
                    .foregroundStyle(Theme.teal)
            }
            HStack {
                Text(run.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(run.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func distanceLabel(_ miles: Double) -> String {
        if let label = DistancePreset.label(forMiles: miles) {
            return label
        }
        return preferences.formatDistance(miles)
    }
}
