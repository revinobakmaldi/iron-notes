# IronNotes

A gym workout tracker for iOS built with SwiftUI and SwiftData. Log sets, track personal records, and visualize your progress with interactive charts.

## Features

**Workout Tracking**
- Log exercises with weight, reps, and set count
- Smart input parser — type `100kg 10r`, `100x10`, or use quick-adjust buttons
- Single-arm exercise support
- Clone previous workouts to quickly start a new session
- Post-workout summary with total volume, sets, and PRs

**Personal Records**
- Automatic PR detection across your workout history
- Estimated 1RM calculation using the Epley formula
- Smart handling of assisted exercises (lower weight = better)

**Analytics**
- Volume breakdown by muscle group (bar chart)
- 1RM progression over time (line chart) with interactive tooltips
- Dashboard stats: total workouts, sets, PRs, and average duration

**Rest Timer**
- Configurable duration (30s–5min)
- Runs in the background with local notifications
- Pause, resume, and adjust time mid-rest

**Exercise Library**
- Organized by muscle group: Chest, Back, Legs, Shoulders, Arms, Core, Full Body
- Add, edit, and remove custom exercises with default weight/reps

## Tech Stack

- **SwiftUI** — Declarative UI
- **SwiftData** — Persistence and relationships
- **Charts** — Native Apple charting framework
- **UserNotifications** — Background rest timer alerts

Requires **iOS 18+**.

## Project Structure

```
IronNotes/
├── IronNotesApp.swift            # Entry point, ModelContainer setup
├── ContentView.swift             # Tab navigation
├── Models.swift                  # SwiftData models (WorkoutSession, ExerciseLog, SetEntry)
├── AppSettings.swift             # Observable settings singleton
├── AnalyticsView.swift           # Home tab — stats & charts
├── WorkoutTab.swift              # Workout history list
├── ActiveWorkoutView.swift       # Live workout session
├── ExerciseCard.swift            # Exercise display component
├── SmartParserInput.swift        # Dual-mode set input (quick / text)
├── RestTimerView.swift           # Rest timer overlay
├── WorkoutSummaryView.swift      # Post-workout summary
├── SettingsView.swift            # Settings tab
├── Parser.swift                  # Text input parser
├── Utilities/
│   ├── PRCalculator.swift        # PR detection logic
│   ├── TimerManager.swift        # Background-aware timer
│   └── HapticManager.swift       # Haptic feedback
└── Extensions/
    └── WorkoutSession+Clone.swift
```

## Getting Started

1. Clone the repo
   ```bash
   git clone https://github.com/revinobakmaldi/iron-notes.git
   ```
2. Open `IronNotes.xcodeproj` in Xcode 16+
3. Build and run on a simulator or device running iOS 18+

## License

This project is for personal use.
