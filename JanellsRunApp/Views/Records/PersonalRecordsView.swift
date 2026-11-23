import SwiftUI
import SwiftData

struct PersonalRecordsView: View {
    @Query(sort: \Run.date, order: .reverse) private var allRuns: [Run]
    @Environment(UserPreferences.self) private var preferences

    @State private var selectedYear: Int?
    @State private var drillDown: Run?

    private var eligibleRuns: [Run] {
        PersonalRecords.eligibleRuns(from: allRuns, includeTraining: preferences.includeTrainingInPRs)
    }

    /// Only years that have something to show, so old imported races are reachable.
    private var yearOptions: [Int] {
        Set(eligibleRuns.map(\.year)).sorted(by: >)
    }

    private var personalRecords: [Run] {
        let runs = selectedYear.map { year in eligibleRuns.filter { $0.year == year } } ?? eligibleRuns
        return PersonalRecords.best(in: runs)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()

                yearPicker
                trainingToggle

                if personalRecords.isEmpty {
                    Spacer()
                    if selectedYear != nil {
                        Text(preferences.includeTrainingInPRs ? "No runs logged for this year." : "No races logged for this year.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Your PRs are gonna look AMAZING here")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    Spacer()
                } else {
                    List(personalRecords) { pr in
                        HStack {
                            prRow(pr)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .editsRun(pr) { drillDown = pr }
                    }
                    .listStyle(.plain)
                    .animation(.default, value: personalRecords.map(\.id))
                }
            }
            .navigationTitle("Personal Records")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $drillDown) { pr in
                DistanceDetailView(distance: pr.distance, includeTraining: preferences.includeTrainingInPRs)
            }
            .onChange(of: yearOptions) {
                if let year = selectedYear, !yearOptions.contains(year) {
                    selectedYear = nil
                }
            }
        }
    }

    private var trainingToggle: some View {
        @Bindable var prefs = preferences
        return Toggle("Include training runs", isOn: $prefs.includeTrainingInPRs.animation())
            .font(.subheadline)
            .tint(Theme.teal)
            .padding(.horizontal)
            .padding(.bottom, 8)
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
