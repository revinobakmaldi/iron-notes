import Foundation
import SwiftData

class PRCalculator {

    static func checkAndMarkPR(
        for setEntry: SetEntry,
        exerciseName: String,
        context: ModelContext,
        sessionDate: Date
    ) {
        let descriptor = FetchDescriptor<SetEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let allSets = try? context.fetch(descriptor) else {
            return
        }

        let current1RM = setEntry.estimated1RM

        let exerciseSets = allSets.filter { set in
            guard let exercise = set.exercise else { return false }
            return exercise.exerciseName == exerciseName && set.id != setEntry.id
        }

        let historicalMax = exerciseSets.map { $0.estimated1RM }.max() ?? 0.0

        let setsInCurrentSession = allSets.filter { set in
            guard let exercise = set.exercise else { return false }
            let session = exercise.session
            return exercise.exerciseName == exerciseName &&
                   session?.date == sessionDate &&
                   set.id != setEntry.id
        }

        let currentSessionHasPR = setsInCurrentSession.contains { $0.isPR }

        if currentSessionHasPR {
            let prSetInSession = setsInCurrentSession.first { $0.isPR }
            let prSet1RM = prSetInSession?.estimated1RM ?? 0.0

            if current1RM > prSet1RM {
                prSetInSession?.isPR = false
                setEntry.isPR = true
            } else {
                setEntry.isPR = false
            }
        } else {
            setEntry.isPR = current1RM > historicalMax
        }
    }

    static func calculateEstimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        return weight * (36 / (37 - Double(reps)))
    }

    static func getHistorical1RMForExercise(exerciseName: String, context: ModelContext) -> Double {
        let descriptor = FetchDescriptor<SetEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let allSets = try? context.fetch(descriptor) else {
            return 0.0
        }

        let exerciseSets = allSets.filter { set in
            guard let exercise = set.exercise else { return false }
            return exercise.exerciseName == exerciseName
        }

        return exerciseSets.map { $0.estimated1RM }.max() ?? 0.0
    }
}