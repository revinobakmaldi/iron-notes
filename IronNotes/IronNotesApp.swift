import SwiftUI
import SwiftData
import UserNotifications
import UIKit

@main
struct IronNotesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutSession.self,
            ExerciseLog.self,
            SetEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        configureThemeAppearance()
        requestNotificationPermission()
    }

    private func configureThemeAppearance() {
        UISlider.appearance().thumbTintColor = UIColor(red: 0.90, green: 0.87, blue: 0.81, alpha: 1)
        UISlider.appearance().minimumTrackTintColor = UIColor(red: 0.09, green: 0.08, blue: 0.07, alpha: 1)
        UISlider.appearance().maximumTrackTintColor = UIColor(red: 0.78, green: 0.74, blue: 0.66, alpha: 1)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(AppSettings.shared)
    }
}
