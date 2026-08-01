import Foundation
import HealthKit
import SwiftData

struct HealthSyncResult {
    let syncedCount: Int
    let skippedCount: Int
}

enum HealthSyncError: LocalizedError {
    case unavailable
    case missingBodyWeight
    case workoutNotReturned

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Health is not available on this device."
        case .missingBodyWeight:
            return "Add body weight in Settings before syncing calories."
        case .workoutNotReturned:
            return "Apple Health saved the workout, but did not return a workout record. Unlock your iPhone and try again."
        }
    }
}

@MainActor
final class HealthSyncManager {
    static let shared = HealthSyncManager()

    private let healthStore = HKHealthStore()

    private init() { }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthSyncError.unavailable
        }

        var shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            shareTypes.insert(activeEnergyType)
        }

        try await healthStore.requestAuthorization(
            toShare: shareTypes,
            read: []
        )
    }

    func sync(session: WorkoutSession, settings: AppSettings, modelContext: ModelContext) async throws -> Bool {
        guard session.isCompleted, session.duration > 0, session.healthKitWorkoutID == nil else {
            return false
        }

        try await requestAuthorization()
        return try await saveAuthorized(session: session, settings: settings, modelContext: modelContext)
    }

    func syncCompletedSessions(
        _ sessions: [WorkoutSession],
        settings: AppSettings,
        modelContext: ModelContext,
        resyncExisting: Bool = false
    ) async throws -> HealthSyncResult {
        if resyncExisting, settings.bodyWeightKg <= 0 {
            throw HealthSyncError.missingBodyWeight
        }

        try await requestAuthorization()

        var syncedCount = 0
        var skippedCount = 0

        for session in sessions.sorted(by: { $0.date < $1.date }) {
            guard session.isCompleted, session.duration > 0 else {
                skippedCount += 1
                continue
            }

            guard session.healthKitWorkoutID == nil || resyncExisting else {
                skippedCount += 1
                continue
            }

            if resyncExisting {
                try await deleteExistingHealthObjects(for: session)
                session.healthKitWorkoutID = nil
            }

            if try await saveAuthorized(session: session, settings: settings, modelContext: modelContext) {
                syncedCount += 1
            } else {
                skippedCount += 1
            }
        }

        return HealthSyncResult(syncedCount: syncedCount, skippedCount: skippedCount)
    }

    private func saveAuthorized(
        session: WorkoutSession,
        settings: AppSettings,
        modelContext: ModelContext
    ) async throws -> Bool {
        let endDate = session.date.addingTimeInterval(TimeInterval(session.duration))
        let estimatedCalories = estimatedCalories(for: session, bodyWeightKg: settings.bodyWeightKg)
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        let metadata: [String: Any] = [
            HKMetadataKeyExternalUUID: session.id.uuidString,
            HKMetadataKeyWorkoutBrandName: "IronNotes",
            "IronNotesWorkoutID": session.id.uuidString,
            "IronNotesExerciseSummary": exerciseSummary(for: session),
            "IronNotesEstimatedCalories": estimatedCalories ?? 0,
            "IronNotesBodyWeightKg": settings.bodyWeightKg,
            "IronNotesHeightCm": settings.heightCm,
            "IronNotesCalorieEstimateMethod": "5.0 MET strength training estimate"
        ]
        let activeEnergy = estimatedCalories.map {
            HKQuantity(unit: .kilocalorie(), doubleValue: $0)
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .unknown

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: nil
        )

        try await builder.beginCollection(at: session.date)
        try await builder.addMetadata(metadata)

        if let activeEnergy, let activeEnergyType {
            let energySample = HKQuantitySample(
                type: activeEnergyType,
                quantity: activeEnergy,
                start: session.date,
                end: endDate,
                metadata: metadata
            )
            try await builder.addSamples([energySample])
        }

        try await builder.endCollection(at: endDate)
        let workout = try await finishWorkout(builder)
        session.healthKitWorkoutID = workout.uuid
        try modelContext.save()
        return true
    }

    private func finishWorkout(_ builder: HKWorkoutBuilder) async throws -> HKWorkout {
        try await withCheckedThrowingContinuation { continuation in
            builder.finishWorkout { workout, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let workout {
                    continuation.resume(returning: workout)
                } else {
                    continuation.resume(throwing: HealthSyncError.workoutNotReturned)
                }
            }
        }
    }

    private func deleteExistingHealthObjects(for session: WorkoutSession) async throws {
        if let workoutID = session.healthKitWorkoutID {
            let workoutPredicate = HKQuery.predicateForObject(with: workoutID)
            try await deleteObjects(of: HKObjectType.workoutType(), predicate: workoutPredicate)
        }

        if let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let energyPredicate = HKQuery.predicateForObjects(
                withMetadataKey: "IronNotesWorkoutID",
                operatorType: .equalTo,
                value: session.id.uuidString
            )
            try await deleteObjects(of: activeEnergyType, predicate: energyPredicate)
        }
    }

    private func deleteObjects(of objectType: HKObjectType, predicate: NSPredicate) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.deleteObjects(of: objectType, predicate: predicate) { success, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthSyncError.unavailable)
                }
            }
        }
    }

    private func estimatedCalories(for session: WorkoutSession, bodyWeightKg: Double) -> Double? {
        guard bodyWeightKg > 0, session.duration > 0 else {
            return nil
        }

        let strengthTrainingMET = 5.0
        let durationHours = Double(session.duration) / 3600
        return (strengthTrainingMET * bodyWeightKg * durationHours).rounded()
    }

    private func exerciseSummary(for session: WorkoutSession) -> String {
        session.exercises
            .sorted { $0.exerciseName < $1.exerciseName }
            .map { exercise in
                let setCount = exercise.sets.reduce(0) { $0 + $1.setCount }
                return "\(exercise.exerciseName): \(setCount) sets"
            }
            .joined(separator: "\n")
    }
}
