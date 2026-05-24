import Testing
@testable import JanellsRunApp

struct DistancePresetTests {
    @Test func labelForKnownDistances() {
        #expect(DistancePreset.label(forMiles: 3.1) == "5K")
        #expect(DistancePreset.label(forMiles: 6.2) == "10K")
        #expect(DistancePreset.label(forMiles: 13.1) == "Half Marathon")
        #expect(DistancePreset.label(forMiles: 26.2) == "Marathon")
        #expect(DistancePreset.label(forMiles: 4.97) == "8K")
    }

    @Test func labelForUnknownDistance() {
        #expect(DistancePreset.label(forMiles: 7.5) == nil)
        #expect(DistancePreset.label(forMiles: 1.0) == nil)
    }

    @Test func matchingPresetWithTolerance() {
        #expect(DistancePreset.matchingPreset(forMiles: 3.1) != nil)
        #expect(DistancePreset.matchingPreset(forMiles: 3.12)?.label == "5K")
        #expect(DistancePreset.matchingPreset(forMiles: 3.08)?.label == "5K")
        #expect(DistancePreset.matchingPreset(forMiles: 2.9) == nil)
    }

    @Test func presetsHaveCorrectKilometerValues() {
        let presets = DistancePreset.presets
        #expect(presets[0].kilometers == 5.0)   // 5K
        #expect(presets[1].kilometers == 8.0)   // 8K
        #expect(presets[2].kilometers == 10.0)  // 10K
        #expect(presets[3].kilometers == 21.1)  // Half Marathon
        #expect(presets[4].kilometers == 42.2)  // Marathon
    }
}
