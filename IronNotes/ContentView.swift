import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var timerManager = TimerManager.shared

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    AnalyticsView()
                }
                    .tabItem {
                        Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)

                WorkoutTab()
                    .tabItem {
                        Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                    }
                    .tag(1)

                NavigationStack {
                    SettingsView()
                }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(2)
            }
            .accentColor(.ironPrimary)
            .preferredColorScheme(.light)

            if timerManager.isVisible {
                RestTimerView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}
