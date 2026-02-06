import Foundation
import SwiftData

class PRCalculator {

    static func isAssistedExercise(_ name: String) -> Bool {
        name.localizedCaseInsensitiveContains("assisted")
    }

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

        let assisted = isAssistedExercise(exerciseName)
        let historicalBest: Double
        if assisted {
            historicalBest = exerciseSets.map { $0.estimated1RM }.min() ?? Double.infinity
        } else {
            historicalBest = exerciseSets.map { $0.estimated1RM }.max() ?? 0.0
        }

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

            let isBetter = assisted ? current1RM < prSet1RM : current1RM > prSet1RM
            if isBetter {
                prSetInSession?.isPR = false
                setEntry.isPR = true
            } else {
                setEntry.isPR = false
            }
        } else {
            let isPR = assisted ? current1RM < historicalBest : current1RM > historicalBest
            setEntry.isPR = isPR
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