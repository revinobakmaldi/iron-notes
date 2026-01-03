# IronNotes - Agent Guidelines

This file guides agentic coding agents working on this iOS fitness tracking application.

## Build, Lint, and Test Commands

```bash
# Build the project
xcodebuild -project IronNotes.xcodeproj -scheme IronNotes -configuration Debug build

# Build for release
xcodebuild -project IronNotes.xcodeproj -scheme IronNotes -configuration Release build

# Clean build
xcodebuild -project IronNotes.xcodeproj -scheme IronNotes clean

# Run all tests (when test targets exist)
xcodebuild test -project IronNotes.xcodeproj -scheme IronTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -project IronNotes.xcodeproj -scheme IronTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IronTests/TestClass/testMethod
```

## Code Style Guidelines

### Project Overview
- iOS fitness tracking app built with SwiftUI and SwiftData
- Swift 5.0, iOS 26.2+ deployment target
- Dark theme UI with haptic feedback
- Gym workout logging with PR tracking and analytics

### Import Style
- Place imports at top of file in this order: Apple frameworks, then third-party
- Group related imports together (Foundation, SwiftUI, SwiftData, UIKit)
- No empty line between import groups
- No alphabetical sorting required

### Formatting
- 4 spaces indentation (no tabs)
- No trailing whitespace
- Empty line between imports and code
- Empty line between function/method definitions
- Spaces around operators: `a + b`, not `a+b`
- Space after comma in function calls: `func(a, b)`, not `func(a,b)`
- Line breaks around long View modifiers using dot notation
- Max line length: ~120 characters preferred

### Types and Naming

**Structs vs Classes**
- Use `struct` for Views (SwiftUI) and data models
- Use `class` for managers, services, and utility objects (HapticManager, PRCalculator, AppSettings)
- Use `final class` for SwiftData models marked with `@Model` macro

**Naming Conventions**
- Types: UpperCamelCase (WorkoutSession, ExerciseCard, HapticManager)
- Functions/Methods: lowerCamelCase (addExercise, checkAndMarkPR)
- Variables/Properties: lowerCamelCase
- Constants: lowerCamelCase
- Boolean properties: prefix with `is` (isSelected, isSingleArm, isPR)
- Enum cases: UPPER_SNAKE_CASE with rawValue (CHEST = "Chest", BACK = "Back")

**Computed Properties**
- Use computed properties for derived data (estimated1RM, lastSet, filteredExercises)
- Keep computed properties lightweight, use private functions for complex logic

### SwiftUI Patterns

**View Structure**
- Mark Views with `struct` conforming to `View`
- Use `@State` for local mutable state
- Use `@Environment(\.modelContext)` for SwiftData context
- Use `@Environment(AppSettings.self)` for app-wide settings
- Use `@Query` for fetching SwiftData models with sort descriptors

**State Management**
- Use `@Observable` macro for observable classes (AppSettings)
- Use `@Binding` for passing state to child Views
- Use `@State private var` for internal state
- Always call `HapticManager.feedback()` on user interactions

**View Modifiers**
- Chain modifiers using dot notation
- Use `.padding()`, `.background()`, `.cornerRadius()` consistently
- Use `.frame(minWidth: 44, minHeight: 44)` for tap targets (accessibility)
- Use `.navigationTitle()` and `.navigationBarTitleDisplayMode()` for navigation
- Use `.sheet()`, `.alert()`, and `.overlay()` for presented content

### SwiftData Patterns

**Model Definitions**
- Mark models with `@Model` macro
- Use `@Relationship(deleteRule: .cascade, inverse: \Inverse.property)` for relationships
- Initialize ID with `UUID()` in init
- Provide default values in init parameters

**Data Operations**
- Use `modelContext.insert()` to add new objects
- Use `modelContext.fetch(descriptor)` with `FetchDescriptor` for queries
- Use `@Query` macro for reactive queries in Views
- Set relationships by assigning parent/child properties

### Error Handling

**Optionals**
- Use `guard let` for early returns with optional unwrapping
- Use `fatalError()` only for unrecoverable errors (ModelContainer initialization)
- Use `??` operator for default values where appropriate
- Return `nil` from methods that can fail gracefully (parse methods)

**Try-Catch**
- Use `try?` for optional operations that can safely fail
- Only use `try`/`catch` when error handling is necessary

### Extensions

- Place extensions in `Extensions/` directory
- Name files as `Type+Functionality.swift` (WorkoutSession+Clone.swift)
- Use extensions to add methods to existing types
- Keep extensions focused and related

### Utilities

- Place utility classes in `Utilities/` directory
- Use static methods for stateless utilities (PRCalculator, HapticManager)
- Use `@Observable` singleton pattern for app-wide state (AppSettings.shared)
- Provide clear feedback methods (success, light, medium, heavy, error, warning)

### Comments

- **No inline comments** unless explaining complex logic
- No file header comments (Xcode adds these automatically)
- Let code be self-documenting through clear naming

### UI/UX Conventions

**Colors**
- Background: `Color.black`
- Primary: `Color.blue`
- Secondary: `Color.gray` with varying opacity
- Accent: `Color.blue.opacity(0.3)` for tags
- Warning: `Color.yellow` for PR indicators

**Typography**
- Titles: `.font(.title2).fontWeight(.bold)` or `.font(.title3).fontWeight(.bold)`
- Headings: `.font(.headline)`
- Body: `.font(.subheadline)` or `.font(.body)`
- Captions: `.font(.caption)`
- Numbers: `.font(.system(size: 36, weight: .bold, design: .rounded))`

**Accessibility**
- Minimum tap target: `44x44` points
- Provide clear labels for buttons and actions
- Use semantic colors and system fonts
