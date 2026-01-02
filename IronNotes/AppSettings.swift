import Foundation
import SwiftUI
import Observation

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    var restTimerDuration: Int = 90
    var preferredUnit: WeightUnit = .kg
    var masterExercises: [MuscleGroup: [MasterExercise]] = [:]
    
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
            masterExercises = decoded.reduce(into: [:]) { dict, pair in
                var newDict = dict
                if let muscleGroup = MuscleGroup(rawValue: pair.key) {
                    newDict[muscleGroup] = pair.value
                }
                return newDict
            }
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(restTimerDuration, forKey: "restTimerDuration")
        UserDefaults.standard.set(preferredUnit.rawValue, forKey: "preferredUnit")
        
        let encodedDict = masterExercises.reduce(into: [String: [MasterExercise]]()) { dict, pair in
            var newDict = dict
            newDict[pair.key.rawValue] = pair.value
            return newDict
        }
        
        if let encoded = try? JSONEncoder().encode(encodedDict) {
            UserDefaults.standard.set(encoded, forKey: "masterExercises")
        }
    }
    
    func addMasterExercise(_ exercise: MasterExercise, for muscleGroup: MuscleGroup) {
        masterExercises[muscleGroup, default: []].append(exercise)
        saveSettings()
    }
    
    func removeMasterExercise(_ exercise: MasterExercise, from muscleGroup: MuscleGroup) {
        masterExercises[muscleGroup]?.removeAll { $0.id == exercise.id }
        saveSettings()
    }
    
    func getExercises(for muscleGroup: MuscleGroup) -> [MasterExercise] {
        masterExercises[muscleGroup] ?? []
    }
}

struct MasterExercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var defaultWeight: Double
    var defaultReps: Int
    
    init(name: String, defaultWeight: Double = 0, defaultReps: Int = 0) {
        self.id = UUID()
        self.name = name
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
    }
}