import SwiftUI
import SwiftData

enum SortField: String, CaseIterable {
    case name, distance, date, time
}

struct RunListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Run.date, order: .reverse) private var allRuns: [Run]

    @State private var showRacesOnly = true
    @State private var sortField: SortField = .date
    @State private var sortAscending = false
    @State private var runToDelete: Run?
    @State private var refreshID = UUID()

    private var filteredRuns: [Run] {
        let filtered = showRacesOnly
            ? allRuns.filter { $0.isRace }
            : allRuns.filter { !$0.isRace }
        return filtered.sorted { a, b in
            let result: Bool
            switch sortField {
            case .name:
                result = a.displayName.localizedCompare(b.displayName) == .orderedAscending
            case .distance:
                result = a.distance < b.distance
            case .date:
                result = a.date < b.date
            case .time:
                result = a.durationSeconds < b.durationSeconds
            }
            return sortAscending ? result : !result
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()

                Picker("Filter", selection: $showRacesOnly) {
                    Text("Races").tag(true)
                    Text("Training").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                sortHeader

                if filteredRuns.isEmpty {
                    Spacer()
                    Text(showRacesOnly ? "No races logged yet." : "No training runs logged yet.")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(Array(filteredRuns.enumerated()), id: \.element.id) { index, run in
                            RunRowView(run: run, isEvenRow: index.isMultiple(of: 2))
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            if let first = offsets.first {
                                runToDelete = filteredRuns[first]
                            }
                        }
                    }
                    .listStyle(.plain)
                    .animation(.default, value: filteredRuns.map(\.id))
                    .refreshable { refreshID = UUID() }
                }
            }
            .navigationTitle("All Runs")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete Run", isPresented: Binding(
                get: { runToDelete != nil },
                set: { if !$0 { runToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let run = runToDelete {
                        withAnimation { modelContext.delete(run) }
                        runToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { runToDelete = nil }
            } message: {
                if let run = runToDelete {
                    Text("Delete \(run.displayName) on \(run.formattedDate)?")
                }
            }
        }
    }

    private var sortHeader: some View {
        HStack {
            sortButton("Name", field: .name, icon: "mappin.and.ellipse")
                .frame(maxWidth: .infinity, alignment: .leading)
            sortButton("Dist", field: .distance, icon: "point.topleft.down.to.point.bottomright.curvepath")
                .frame(width: 55)
            sortButton("Date", field: .date, icon: "calendar")
                .frame(width: 75)
            sortButton("Time", field: .time, icon: "stopwatch")
                .frame(width: 75)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.darkBackground)
    }

    private func sortButton(_ label: String, field: SortField, icon: String) -> some View {
        Button {
            if sortField == field {
                sortAscending.toggle()
            } else {
                sortField = field
                sortAscending = field == .name
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: icon)
                if sortField == field {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .foregroundStyle(sortField == field ? Theme.teal : Theme.offWhite)
            .font(.body)
        }
    }

}
