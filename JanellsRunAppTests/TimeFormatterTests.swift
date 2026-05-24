import Testing
@testable import JanellsRunApp

struct TimeFormatterTests {
    @Test func formatsHoursMinutesSeconds() {
        #expect(TimeFormatter.formatted(3661) == "01:01:01")
        #expect(TimeFormatter.formatted(7200) == "02:00:00")
    }

    @Test func formatsMinutesSecondsOnly() {
        #expect(TimeFormatter.formatted(90) == "00:01:30")
        #expect(TimeFormatter.formatted(60) == "00:01:00")
        #expect(TimeFormatter.formatted(599) == "00:09:59")
    }

    @Test func formatsSecondsOnly() {
        #expect(TimeFormatter.formatted(0) == "00:00:00")
        #expect(TimeFormatter.formatted(59) == "00:00:59")
        #expect(TimeFormatter.formatted(5) == "00:00:05")
    }

    @Test func totalSecondsCalculation() {
        #expect(TimeFormatter.totalSeconds(hours: 1, minutes: 2, seconds: 3) == 3723)
        #expect(TimeFormatter.totalSeconds(hours: 0, minutes: 30, seconds: 0) == 1800)
        #expect(TimeFormatter.totalSeconds(hours: 0, minutes: 0, seconds: 45) == 45)
    }
}
