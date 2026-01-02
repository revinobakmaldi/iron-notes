import Foundation
import SwiftUI
import Observation

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    var restTimerDuration: Int = 90
    var preferredUnit: WeightUnit = .kg
    
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
    }
    
    func saveSettings() {
        UserDefaults.standard.set(restTimerDuration, forKey: "restTimerDuration")
        UserDefaults.standard.set(preferredUnit.rawValue, forKey: "preferredUnit")
    }
}