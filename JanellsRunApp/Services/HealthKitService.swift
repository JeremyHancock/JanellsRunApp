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

    private func fetchDistance(for workout: HKWorkout) async -> Double {
        let distanceType = HKQuantityType(.distanceWalkingRunning)
        let timePredicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        let sourcePredicate = HKQuery.predicateForObjects(from: workout.sourceRevision.source)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, sourcePredicate])

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let miles = statistics?.sumQuantity()?.doubleValue(for: .mile()) ?? 0
                continuation.resume(returning: miles)
            }
            store.execute(query)
        }
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

                let hkWorkouts = samples as? [HKWorkout] ?? []
                Task {
                    var results: [HealthKitWorkout] = []
                    for workout in hkWorkouts {
                        var distance = workout.totalDistance?.doubleValue(for: .mile()) ?? 0

                        if distance == 0 {
                            distance = await self.fetchDistance(for: workout)
                        }

                        results.append(HealthKitWorkout(
                            id: workout.uuid.uuidString,
                            date: workout.startDate,
                            distance: (distance * 100).rounded() / 100,
                            durationSeconds: Int(workout.duration)
                        ))
                    }
                    continuation.resume(returning: results)
                }
            }

            store.execute(query)
        }
    }
}
