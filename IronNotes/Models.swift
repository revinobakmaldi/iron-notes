import Foundation
import SwiftData

enum MuscleGroup: String, CaseIterable, Codable {
    case CHEST = "Chest"
    case BACK = "Back"
    case LEGS = "Legs"
    case SHOULDERS = "Shoulders"
    case ARMS = "Arms"
    case CORE = "Core"
    case FULL_BODY = "Full Body"

    /// Muscle groups selectable for exercises (excludes split-level categories like Full Body)
    static var selectableCases: [MuscleGroup] {
        allCases.filter { $0 != .FULL_BODY }
    }
}

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var notes: String
    var duration: Int
    var isCompleted: Bool
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exercises: [ExerciseLog]

    init(date: Date = Date(), notes: String = "") {
        self.id = UUID()
        self.date = date
        self.notes = notes
        self.duration = 0
        self.isCompleted = false
        self.exercises = []
    }
}

@Model
final class ExerciseLog {
    var id: UUID
    var exerciseName: String
    var muscleGroup: MuscleGroup
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.exercise)
    var sets: [SetEntry]
    var session: WorkoutSession?

    init(name: String, muscleGroup: MuscleGroup) {
        self.id = UUID()
        self.exerciseName = name
        self.muscleGroup = muscleGroup
        self.sets = []
    }

    var estimated1RM: Double {
        sets.map { $0.estimated1RM }.max() ?? 0.0
    }
}

@Model
final class SetEntry {
    var id: UUID
    var weight: Double
    var reps: Int
    var setCount: Int
    var isSingleArm: Bool
    var timestamp: Date
    var isPR: Bool
    var exercise: ExerciseLog?

    var estimated1RM: Double {
        weight * (36 / (37 - Double(reps)))
    }

    init(weight: Double, reps: Int, setCount: Int = 1, isSingleArm: Bool = false) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.setCount = setCount
        self.isSingleArm = isSingleArm
        self.timestamp = Date()
        self.isPR = false
    }
}

struct MasterExercise: Identifiable, Codable {
    var id: UUID
    var name: String
    var defaultWeight: Double
    var defaultReps: Int

    init(name: String, defaultWeight: Double = 0, defaultReps: Int = 0, id: UUID? = nil) {
        self.id = id ?? UUID()
        self.name = name
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
    }
}