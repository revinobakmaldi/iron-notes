import Foundation
import SwiftUI
import Observation

@Observable
class AppSettings {
    static let shared = AppSettings()

    var restTimerDuration: Int = 90
    var preferredUnit: WeightUnit = .kg
    var masterExercises: [String: [MasterExercise]] = [:]

    enum WeightUnit: String, CaseIterable {
        case kg = "kg"
        case lb = "lb"
    }

    private init() {
        loadSettings()
    }

    private func loadSettings() {
        let savedDuration = UserDefaults.standard.integer(forKey: "restTimerDuration")
        if savedDuration > 0 {
            restTimerDuration = savedDuration
        }

        if let savedUnit = UserDefaults.standard.string(forKey: "preferredUnit"),
           let unit = WeightUnit(rawValue: savedUnit) {
            preferredUnit = unit
        }

        if let savedExercises = UserDefaults.standard.data(forKey: "masterExercises"),
           let decoded = try? JSONDecoder().decode([String: [MasterExercise]].self, from: savedExercises) {
            masterExercises = decoded
        }

        if masterExercises.isEmpty {
            masterExercises = Self.defaultMasterExercises
            saveSettings()
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(restTimerDuration, forKey: "restTimerDuration")
        UserDefaults.standard.set(preferredUnit.rawValue, forKey: "preferredUnit")

        if let encoded = try? JSONEncoder().encode(masterExercises) {
            UserDefaults.standard.set(encoded, forKey: "masterExercises")
        }
    }

    func addMasterExercise(_ exercise: MasterExercise, for muscleGroup: MuscleGroup) {
        masterExercises[muscleGroup.rawValue, default: []].append(exercise)
        saveSettings()
    }

    func removeMasterExercise(_ exercise: MasterExercise, from muscleGroup: MuscleGroup) {
        masterExercises[muscleGroup.rawValue, default: []].removeAll { $0.id == exercise.id }
        saveSettings()
    }

    func updateMasterExercise(_ exercise: MasterExercise, for muscleGroup: MuscleGroup) {
        guard let index = masterExercises[muscleGroup.rawValue, default: []].firstIndex(where: { $0.id == exercise.id }) else { return }
        masterExercises[muscleGroup.rawValue]?[index] = exercise
        saveSettings()
    }

    func getExercises(for muscleGroup: MuscleGroup) -> [MasterExercise] {
        masterExercises[muscleGroup.rawValue] ?? []
    }

    func ensureDefaultMasterExercises() {
        guard masterExercises.isEmpty else { return }
        masterExercises = Self.defaultMasterExercises
        saveSettings()
    }

    private static var defaultMasterExercises: [String: [MasterExercise]] {
        [
            MuscleGroup.CHEST.rawValue: [
                MasterExercise(name: "Bench Press", defaultWeight: 70, defaultReps: 8),
                MasterExercise(name: "Incline Dumbbell Press", defaultWeight: 24, defaultReps: 10),
                MasterExercise(name: "Cable Fly", defaultWeight: 15, defaultReps: 12),
                MasterExercise(name: "Push Up", defaultWeight: 0, defaultReps: 15)
            ],
            MuscleGroup.BACK.rawValue: [
                MasterExercise(name: "Lat Pulldown", defaultWeight: 60, defaultReps: 10),
                MasterExercise(name: "Seated Cable Row", defaultWeight: 55, defaultReps: 10),
                MasterExercise(name: "Barbell Row", defaultWeight: 60, defaultReps: 8),
                MasterExercise(name: "Assisted Pull Up", defaultWeight: 35, defaultReps: 8)
            ],
            MuscleGroup.LEGS.rawValue: [
                MasterExercise(name: "Back Squat", defaultWeight: 90, defaultReps: 6),
                MasterExercise(name: "Romanian Deadlift", defaultWeight: 75, defaultReps: 8),
                MasterExercise(name: "Leg Press", defaultWeight: 160, defaultReps: 12),
                MasterExercise(name: "Walking Lunge", defaultWeight: 20, defaultReps: 12)
            ],
            MuscleGroup.SHOULDERS.rawValue: [
                MasterExercise(name: "Shoulder Press", defaultWeight: 35, defaultReps: 8),
                MasterExercise(name: "Lateral Raise", defaultWeight: 8, defaultReps: 15),
                MasterExercise(name: "Rear Delt Fly", defaultWeight: 8, defaultReps: 15),
                MasterExercise(name: "Face Pull", defaultWeight: 20, defaultReps: 15)
            ],
            MuscleGroup.ARMS.rawValue: [
                MasterExercise(name: "Dumbbell Curl", defaultWeight: 12, defaultReps: 12),
                MasterExercise(name: "Triceps Pushdown", defaultWeight: 32.5, defaultReps: 12),
                MasterExercise(name: "Hammer Curl", defaultWeight: 14, defaultReps: 10),
                MasterExercise(name: "Overhead Triceps Extension", defaultWeight: 20, defaultReps: 12)
            ],
            MuscleGroup.CORE.rawValue: [
                MasterExercise(name: "Plank", defaultWeight: 0, defaultReps: 60),
                MasterExercise(name: "Hanging Knee Raise", defaultWeight: 0, defaultReps: 12),
                MasterExercise(name: "Cable Crunch", defaultWeight: 30, defaultReps: 15),
                MasterExercise(name: "Russian Twist", defaultWeight: 10, defaultReps: 20)
            ]
        ]
    }
}
