import Foundation
import HealthKit
import SwiftData

struct HealthSyncResult {
    let syncedCount: Int
    let skippedCount: Int
}

enum HealthSyncError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Health is not available on this device."
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
        modelContext: ModelContext
    ) async throws -> HealthSyncResult {
        try await requestAuthorization()

        var syncedCount = 0
        var skippedCount = 0

        for session in sessions.sorted(by: { $0.date < $1.date }) {
            guard session.isCompleted, session.duration > 0, session.healthKitWorkoutID == nil else {
                skippedCount += 1
                continue
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

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: session.date,
            end: endDate,
            duration: TimeInterval(session.duration),
            totalEnergyBurned: activeEnergy,
            totalDistance: nil,
            metadata: metadata
        )

        try await healthStore.save(workout)
        session.healthKitWorkoutID = workout.uuid
        try modelContext.save()
        return true
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
