import Testing
@testable import JanellsRunApp

struct EventSearchTests {
    private let names = ["Monument Avenue 10K", "Richmond Marathon"]

    @Test func offersTypedNameWhenNoEventHasIt() {
        #expect(EventSearch.newEventName(forSearch: "  Turkey Trot ", existingNames: names) == "Turkey Trot")
        // A partial match is still a new name
        #expect(EventSearch.newEventName(forSearch: "Monument", existingNames: names) == "Monument")
    }

    @Test func offersNothingForEmptyOrExistingName() {
        #expect(EventSearch.newEventName(forSearch: "   ", existingNames: names) == nil)
        #expect(EventSearch.newEventName(forSearch: "richmond marathon", existingNames: names) == nil)
    }
}
