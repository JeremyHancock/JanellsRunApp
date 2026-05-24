import SwiftUI

struct RunRowView: View {
    let run: Run
    let isEvenRow: Bool
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        HStack {
            Text(run.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            Text(preferences.formatNumber(preferences.displayDistance(run.distance)))
                .frame(width: 55, alignment: .trailing)
                .foregroundStyle(.secondary)

            Text(run.formattedDate)
                .frame(width: 75, alignment: .center)

            Text(run.formattedTime)
                .frame(width: 75, alignment: .trailing)
                .monospacedDigit()
        }
        .font(.subheadline)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isEvenRow ? Color(.systemBackground) : Theme.tableGray.opacity(0.3))
    }
}
