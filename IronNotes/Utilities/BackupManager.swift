import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct IronNotesBackup: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var settings: BackupSettings
    var workouts: [BackupWorkoutSession]
}

struct BackupSettings: Codable {
    var restTimerDuration: Int
    var preferredUnit: String
    var masterExercises: [String: [MasterExercise]]
}

struct BackupWorkoutSession: Codable {
    var id: UUID
    var date: Date
    var notes: String
    var duration: Int
    var isCompleted: Bool
    var exercises: [BackupExerciseLog]
}

struct BackupExerciseLog: Codable {
    var id: UUID
    var exerciseName: String
    var muscleGroup: MuscleGroup
    var sets: [BackupSetEntry]
}

struct BackupSetEntry: Codable {
    var id: UUID
    var weight: Double
    var reps: Int
    var setCount: Int
    var isSingleArm: Bool
    var timestamp: Date
    var isPR: Bool
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum BackupError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case invalidPreferredUnit(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Unsupported backup schema version: \(version)"
        case .invalidPreferredUnit(let unit):
            return "Unsupported preferred unit: \(unit)"
        }
    }
}

@MainActor
enum BackupManager {
    static func makeBackup(
        sessions: [WorkoutSession],
        settings: AppSettings
    ) throws -> BackupDocument {
        let backup = IronNotesBackup(
            schemaVersion: 1,
            exportedAt: Date(),
            settings: BackupSettings(
                restTimerDuration: settings.restTimerDuration,
                preferredUnit: settings.preferredUnit.rawValue,
                masterExercises: settings.masterExercises
            ),
            workouts: sessions
                .sorted { $0.date < $1.date }
                .map(backupSession)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return BackupDocument(data: try encoder.encode(backup))
    }

    static func importBackup(
        data: Data,
        modelContext: ModelContext,
        existingSessions: [WorkoutSession],
        settings: AppSettings
    ) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(IronNotesBackup.self, from: data)

        guard backup.schemaVersion == 1 else {
            throw BackupError.unsupportedSchemaVersion(backup.schemaVersion)
        }

        guard let preferredUnit = AppSettings.WeightUnit(rawValue: backup.settings.preferredUnit) else {
            throw BackupError.invalidPreferredUnit(backup.settings.preferredUnit)
        }

        for session in existingSessions {
            modelContext.delete(session)
        }

        settings.restTimerDuration = backup.settings.restTimerDuration
        settings.preferredUnit = preferredUnit
        settings.masterExercises = backup.settings.masterExercises
        settings.saveSettings()

        for backupSession in backup.workouts {
            modelContext.insert(makeSession(from: backupSession))
        }

        try modelContext.save()
    }

    private static func backupSession(_ session: WorkoutSession) -> BackupWorkoutSession {
        BackupWorkoutSession(
            id: session.id,
            date: session.date,
            notes: session.notes,
            duration: session.duration,
            isCompleted: session.isCompleted,
            exercises: session.exercises
                .sorted { $0.exerciseName < $1.exerciseName }
                .map(backupExercise)
        )
    }

    private static func backupExercise(_ exercise: ExerciseLog) -> BackupExerciseLog {
        BackupExerciseLog(
            id: exercise.id,
            exerciseName: exercise.exerciseName,
            muscleGroup: exercise.muscleGroup,
            sets: exercise.sets
                .sorted { $0.timestamp < $1.timestamp }
                .map(backupSet)
        )
    }

    private static func backupSet(_ set: SetEntry) -> BackupSetEntry {
        BackupSetEntry(
            id: set.id,
            weight: set.weight,
            reps: set.reps,
            setCount: set.setCount,
            isSingleArm: set.isSingleArm,
            timestamp: set.timestamp,
            isPR: set.isPR
        )
    }

    private static func makeSession(from backup: BackupWorkoutSession) -> WorkoutSession {
        let session = WorkoutSession(date: backup.date, notes: backup.notes)
        session.id = backup.id
        session.duration = backup.duration
        session.isCompleted = backup.isCompleted

        session.exercises = backup.exercises.map { backupExercise in
            let exercise = makeExercise(from: backupExercise)
            exercise.session = session
            return exercise
        }

        return session
    }

    private static func makeExercise(from backup: BackupExerciseLog) -> ExerciseLog {
        let exercise = ExerciseLog(name: backup.exerciseName, muscleGroup: backup.muscleGroup)
        exercise.id = backup.id

        exercise.sets = backup.sets.map { backupSet in
            let set = makeSet(from: backupSet)
            set.exercise = exercise
            return set
        }

        return exercise
    }

    private static func makeSet(from backup: BackupSetEntry) -> SetEntry {
        let set = SetEntry(
            weight: backup.weight,
            reps: backup.reps,
            setCount: backup.setCount,
            isSingleArm: backup.isSingleArm
        )
        set.id = backup.id
        set.timestamp = backup.timestamp
        set.isPR = backup.isPR
        return set
    }
}
