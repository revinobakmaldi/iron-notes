import Foundation
import SwiftData

extension WorkoutSession {

    static func cloneLastSession(context: ModelContext) -> WorkoutSession {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let allSessions = try? context.fetch(descriptor),
              let sessionToClone = allSessions.first else {
            return WorkoutSession(date: Date())
        }

        let newSession = WorkoutSession(date: Date())

        for exercise in sessionToClone.exercises {
            let clonedExercise = ExerciseLog(
                name: exercise.exerciseName,
                muscleGroup: exercise.muscleGroup
            )
            clonedExercise.session = newSession
            newSession.exercises.append(clonedExercise)
        }

        return newSession
    }
    
    func getPreviousSessionData(exerciseName: String, context: ModelContext) -> [SetEntry] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? context.fetch(descriptor) else {
            return []
        }
        
        let previousSessions = allSessions.filter { $0.id != self.id }
        
        for session in previousSessions {
            for exercise in session.exercises {
                if exercise.exerciseName == exerciseName {
                    return exercise.sets
                }
            }
        }
        
        return []
    }
}