import SwiftUI

enum DistanceUnit: String, CaseIterable {
    case miles = "Miles"
    case kilometers = "Kilometers"

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    var conversionFromMiles: Double {
        switch self {
        case .miles: return 1.0
        case .kilometers: return 1.60934
        }
    }

    var conversionToMiles: Double {
        switch self {
        case .miles: return 1.0
        case .kilometers: return 0.621371
        }
    }
}

enum AppAppearance: String, CaseIterable {
    case system = "Device"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Observable
final class UserPreferences {
    var distanceUnit: DistanceUnit {
        didSet {
            UserDefaults.standard.set(distanceUnit.rawValue, forKey: "distanceUnit")
        }
    }

    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appearance")
        }
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: "distanceUnit"),
           let unit = DistanceUnit(rawValue: stored) {
            self.distanceUnit = unit
        } else {
            self.distanceUnit = .miles
        }

        if let stored = UserDefaults.standard.string(forKey: "appearance"),
           let mode = AppAppearance(rawValue: stored) {
            self.appearance = mode
        } else {
            self.appearance = .system
        }
    }

    func displayDistance(_ miles: Double) -> Double {
        if distanceUnit == .kilometers,
           let preset = DistancePreset.matchingPreset(forMiles: miles) {
            return preset.kilometers
        }
        return miles * distanceUnit.conversionFromMiles
    }

    func formatDistance(_ miles: Double) -> String {
        "\(formatNumber(displayDistance(miles))) \(distanceUnit.abbreviation)"
    }

    func formatNumber(_ value: Double) -> String {
        let s = String(format: "%.2f", value)
        if s.contains(".") {
            return s.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
        }
        return s
    }
}
