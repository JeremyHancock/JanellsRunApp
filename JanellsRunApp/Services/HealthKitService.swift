import Foundation
import HealthKit

@Observable
final class HealthKitService {
    private let store = HKHealthStore()
    var isAuthorized = false
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.distanceWalkingRunning),
        ]

        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    func fetchRunningWorkouts(since date: Date? = nil) async throws -> [HealthKitWorkout] {
        let workoutType = HKObjectType.workoutType()

        var predicates: [NSPredicate] = [
            HKQuery.predicateForWorkouts(with: .running)
        ]
        if let date {
            predicates.append(HKQuery.predicateForSamples(
                withStart: date,
                end: nil,
                options: .strictStartDate
            ))
        }

        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: compound,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                    let distance = workout.totalDistance?.doubleValue(for: .mile()) ?? 0
                    let duration = Int(workout.duration)

                    return HealthKitWorkout(
                        id: workout.uuid.uuidString,
                        date: workout.startDate,
                        distance: (distance * 100).rounded() / 100,
                        durationSeconds: duration
                    )
                }

                continuation.resume(returning: workouts)
            }

            store.execute(query)
        }
    }
}
