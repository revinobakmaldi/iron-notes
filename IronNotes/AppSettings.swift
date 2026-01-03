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

    func getExercises(for muscleGroup: MuscleGroup) -> [MasterExercise] {
        masterExercises[muscleGroup.rawValue] ?? []
    }
}