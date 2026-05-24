import SwiftUI

struct DistancePicker: View {
    @Binding var selectedPreset: DistancePreset?
    @Binding var customDistance: String
    @Environment(UserPreferences.self) private var preferences
    var isCustom: Bool { selectedPreset == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DistancePreset.presets) { preset in
                        Button {
                            selectedPreset = preset
                            customDistance = ""
                        } label: {
                            Text(preset.label)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedPreset == preset ? Theme.teal : Theme.tableGray)
                                .foregroundStyle(selectedPreset == preset ? Theme.offWhite : .primary)
                                .clipShape(Capsule())
                        }
                    }

                    Button {
                        selectedPreset = nil
                    } label: {
                        Text("Custom")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isCustom ? Theme.teal : Theme.tableGray)
                            .foregroundStyle(isCustom ? Theme.offWhite : .primary)
                            .clipShape(Capsule())
                    }
                }
            }

            if isCustom {
                HStack {
                    TextField(preferences.distanceUnit.abbreviation, text: $customDistance)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text(preferences.distanceUnit.abbreviation)
                        .foregroundStyle(.secondary)
                }
            } else if let preset = selectedPreset {
                Text(preferences.formatDistance(preset.miles))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
