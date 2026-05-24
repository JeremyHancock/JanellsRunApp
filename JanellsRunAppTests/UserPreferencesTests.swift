import Testing
@testable import JanellsRunApp

struct UserPreferencesTests {
    @Test func formatNumberDropsTrailingZeroes() {
        let prefs = UserPreferences()
        #expect(prefs.formatNumber(10.00) == "10")
        #expect(prefs.formatNumber(3.10) == "3.1")
        #expect(prefs.formatNumber(5.55) == "5.55")
        #expect(prefs.formatNumber(0.50) == "0.5")
        #expect(prefs.formatNumber(42.20) == "42.2")
    }

    @Test func formatDistanceMiles() {
        let prefs = UserPreferences()
        prefs.distanceUnit = .miles
        #expect(prefs.formatDistance(3.1) == "3.1 mi")
        #expect(prefs.formatDistance(6.2) == "6.2 mi")
        #expect(prefs.formatDistance(5.55) == "5.55 mi")
    }

    @Test func formatDistanceKilometers() {
        let prefs = UserPreferences()
        prefs.distanceUnit = .kilometers

        // Known presets should use exact km values
        #expect(prefs.formatDistance(3.1) == "5 km")    // 5K
        #expect(prefs.formatDistance(6.2) == "10 km")   // 10K
        #expect(prefs.formatDistance(13.1) == "21.1 km") // Half Marathon
        #expect(prefs.formatDistance(26.2) == "42.2 km") // Marathon
    }

    @Test func formatDistanceKilometersNonPreset() {
        let prefs = UserPreferences()
        prefs.distanceUnit = .kilometers

        let result = prefs.formatDistance(7.5)
        #expect(result.hasSuffix("km"))
        #expect(result.contains("12.07")) // 7.5 * 1.60934
    }

    @Test func displayDistanceIdentityForMiles() {
        let prefs = UserPreferences()
        prefs.distanceUnit = .miles
        #expect(prefs.displayDistance(5.0) == 5.0)
    }

    @Test func displayDistanceConvertsToKm() {
        let prefs = UserPreferences()
        prefs.distanceUnit = .kilometers

        // Non-preset distance: mathematical conversion
        let result = prefs.displayDistance(1.0)
        #expect(abs(result - 1.60934) < 0.001)
    }

    @Test func displayDistanceUsesExactKmForPresets() {
        let prefs = UserPreferences()
        prefs.distanceUnit = .kilometers

        #expect(prefs.displayDistance(3.1) == 5.0)
        #expect(prefs.displayDistance(6.2) == 10.0)
        #expect(prefs.displayDistance(13.1) == 21.1)
    }

    @Test func distanceUnitConversions() {
        #expect(DistanceUnit.miles.conversionFromMiles == 1.0)
        #expect(DistanceUnit.miles.conversionToMiles == 1.0)
        #expect(abs(DistanceUnit.kilometers.conversionFromMiles - 1.60934) < 0.001)
        #expect(abs(DistanceUnit.kilometers.conversionToMiles - 0.621371) < 0.001)
    }

    @Test func distanceUnitAbbreviations() {
        #expect(DistanceUnit.miles.abbreviation == "mi")
        #expect(DistanceUnit.kilometers.abbreviation == "km")
    }
}
