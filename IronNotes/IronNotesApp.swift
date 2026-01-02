//
//  IronNotesApp.swift
//  IronNotes
//
//  Created by Revino B Akmaldi on 02/01/26.
//

import SwiftUI
import SwiftData

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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(AppSettings.shared)
    }
}
