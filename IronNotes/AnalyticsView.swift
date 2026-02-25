import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [WorkoutSession]
    @Query(filter: #Predicate<WorkoutSession> { !$0.isCompleted })
    private var activeSessions: [WorkoutSession]
    @Environment(AppSettings.self) private var settings

    @State private var showNewWorkout = false

    var hasActiveSession: Bool {
        !activeSessions.isEmpty
    }

    var workoutsThisWeek: Int {
        last7DaysSessions.count
    }

    var daysSinceLastWorkout: Int {
        guard let lastWorkout = sessions.filter({ $0.isCompleted }).sorted(by: { $0.date > $1.date }).first else {
            return 999
        }
        let days = Calendar.current.dateComponents([.day], from: lastWorkout.date, to: Date()).day ?? 0
        return days
    }

    var longestUntrainedMuscle: (group: MuscleGroup, days: Int)? {
        let calendar = Calendar.current
        let completedSessions = sessions.filter { $0.isCompleted }
        guard !completedSessions.isEmpty else { return nil }

        var oldest: (group: MuscleGroup, days: Int)?

        for muscle in MuscleGroup.selectableCases {
            let lastTrained = completedSessions
                .filter { session in session.exercises.contains { $0.muscleGroup == muscle } }
                .map(\.date)
                .max()

            let days: Int
            if let lastDate = lastTrained {
                days = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            } else {
                days = 999
            }

            if let current = oldest {
                if days > current.days { oldest = (muscle, days) }
            } else {
                oldest = (muscle, days)
            }
        }

        return oldest
    }

    var contextualCTA: String {
        let daySeed = Calendar.current.component(.day, from: Date())
        let completedSessions = sessions.filter { $0.isCompleted }

        func pick(_ options: [String]) -> String {
            options[daySeed % options.count]
        }

        // Priority 1: No sessions ever
        if completedSessions.isEmpty {
            return pick([
                "Every PR starts with rep one.",
                "Iron therapy starts now.",
                "The hardest part is showing up. You're here."
            ])
        }

        // Priority 2: Rest days >= 3
        if consecutiveRestDays >= 3 {
            return pick([
                "\(consecutiveRestDays) days off — the barbell misses you.",
                "Your muscles are recovered. Time to go.",
                "Rest is done. Let's work."
            ])
        }

        // Priority 3: Worked out today
        if daysSinceLastWorkout == 0 {
            return pick([
                "Already crushed it today. Legend.",
                "Double session? Respect.",
                "Today's work is done. Recovery mode."
            ])
        }

        // Priority 4: Longest untrained muscle group >= 5 days
        if let untrained = longestUntrainedMuscle, untrained.days >= 5, untrained.days < 999 {
            let name = untrained.group.rawValue
            return pick([
                "\(name) was \(untrained.days) days ago...",
                "\(name) is waiting for you."
            ])
        }

        // Priority 5: Good streak (3+ days this week)
        if workoutsThisWeek >= 3 {
            return pick([
                "\(workoutsThisWeek) days in — momentum is real.",
                "Consistency beats intensity.",
                "You're on a roll this week."
            ])
        }

        // Priority 6: Fallback
        return pick([
            "Trust the process.",
            "One more set than yesterday.",
            "Discipline over motivation.",
            "Show up. Lift. Repeat."
        ])
    }

    let muscleGroupColors: [MuscleGroup: Color] = [
        .CHEST: Color(red: 0.95, green: 0.45, blue: 0.35),
        .BACK: Color(red: 0.35, green: 0.55, blue: 0.9),
        .LEGS: Color(red: 0.35, green: 0.8, blue: 0.45),
        .SHOULDERS: Color(red: 0.95, green: 0.65, blue: 0.25),
        .ARMS: Color(red: 0.75, green: 0.4, blue: 0.8),
        .CORE: Color(red: 0.35, green: 0.7, blue: 0.85)
    ]

    // MARK: - Data Filtering

    private var sevenDaysAgo: Date {
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date())
    }

    private var last7DaysSessions: [WorkoutSession] {
        sessions.filter { $0.isCompleted && $0.date >= sevenDaysAgo }
    }

    private var priorSessions: [WorkoutSession] {
        sessions.filter { $0.isCompleted && $0.date < sevenDaysAgo }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                motivationalHeader
                startWorkoutButton

                Text(contextualCTA)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)

                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 24) {
                        weeklyCalendarStrip
                        restDayWarning
                        weeklyDurationSummary
                        weeklySetsByMuscleGroup
                        topSetHighlights
                        strengthProgress
                        trainingGaps
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top)
        }
        .background(Color.black)
        .navigationTitle("IronNotes")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showNewWorkout) {
            NewWorkoutSheet(isPresented: $showNewWorkout)
        }
    }

    // MARK: - Motivational Header

    private var motivationalHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Label("\(workoutsThisWeek) \(workoutsThisWeek == 1 ? "workout" : "workouts") this week", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                if sessions.isEmpty {
                    Text("Ready to start?")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                } else if daysSinceLastWorkout == 0 {
                    Text("Last workout: Today!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else if daysSinceLastWorkout == 1 {
                    Text("Last workout: Yesterday")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("Last workout: \(daysSinceLastWorkout) days ago")
                        .font(.subheadline)
                        .foregroundColor(daysSinceLastWorkout > 3 ? .orange : .gray)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Start Workout Button

    private var startWorkoutButton: some View {
        Group {
            if hasActiveSession, let activeSession = activeSessions.first {
                NavigationLink(destination: ActiveWorkoutView(session: activeSession)) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("Resume Workout")
                            .font(.headline)
                        Spacer()
                        Text(activeSession.exercises.count > 0 ? "\(activeSession.exercises.count) exercises" : "New")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            } else {
                Button(action: {
                    HapticManager.medium()
                    showNewWorkout = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Start Workout")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Complete workouts to see your progress")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Section 1: Weekly Gym Activity

    private var last7CalendarDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        }
    }

    private func hasWorkoutOn(date: Date) -> Bool {
        let calendar = Calendar.current
        return last7DaysSessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
    }

    private var gymDaysCount: Int {
        last7CalendarDays.filter { hasWorkoutOn(date: $0) }.count
    }

    private var weeklyCalendarStrip: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Activity")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 0) {
                ForEach(last7CalendarDays, id: \.self) { day in
                    let hasWorkout = hasWorkoutOn(date: day)
                    let isToday = Calendar.current.isDateInToday(day)
                    VStack(spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)).prefix(3))
                            .font(.caption2)
                            .foregroundColor(.gray)

                        ZStack {
                            Circle()
                                .fill(hasWorkout ? Color.blue : Color.gray.opacity(0.15))
                                .frame(width: 36, height: 36)

                            if hasWorkout {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else {
                                Text(day.formatted(.dateTime.day()))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .overlay(
                            Circle()
                                .strokeBorder(isToday ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                                .frame(width: 36, height: 36)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text("\(gymDaysCount) of 7 days")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
    }

    // MARK: - Section 2: Weekly Sets by Muscle Group

    private var weeklySetsByMuscle: [(muscleGroup: MuscleGroup, sets: Int)] {
        var setsPerMuscle: [MuscleGroup: Int] = [:]

        for session in last7DaysSessions {
            for exercise in session.exercises {
                setsPerMuscle[exercise.muscleGroup, default: 0] += exercise.sets.count
            }
        }

        return setsPerMuscle
            .map { (muscleGroup: $0.key, sets: $0.value) }
            .sorted { $0.sets > $1.sets }
    }

    private var weeklySetsByMuscleGroup: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Sets by Muscle Group")
                .font(.headline)
                .foregroundColor(.white)

            if weeklySetsByMuscle.isEmpty {
                Text("No sets recorded this week")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                let maxSets = weeklySetsByMuscle.map(\.sets).max() ?? 1

                VStack(spacing: 12) {
                    ForEach(weeklySetsByMuscle, id: \.muscleGroup) { item in
                        HStack(spacing: 12) {
                            Text(item.muscleGroup.rawValue)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .trailing)

                            GeometryReader { geo in
                                let barWidth = max(CGFloat(item.sets) / CGFloat(maxSets) * geo.size.width, 30)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(muscleGroupColors[item.muscleGroup] ?? .blue)
                                    .frame(width: barWidth, height: 28)
                                    .overlay(
                                        Text("\(item.sets)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8),
                                        alignment: .trailing
                                    )
                            }
                            .frame(height: 28)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
    }

    // MARK: - Section 3: Strength Progress

    private struct ExerciseProgress: Identifiable {
        let id = UUID()
        let exerciseName: String
        let muscleGroup: MuscleGroup
        let thisWeekBest: Double
        let priorBest: Double?
        let isAssisted: Bool

        var trend: Trend {
            guard let prior = priorBest else { return .new }
            if isAssisted {
                if thisWeekBest < prior { return .improved }
                else if thisWeekBest > prior { return .regressed }
                else { return .same }
            } else {
                if thisWeekBest > prior { return .improved }
                else if thisWeekBest < prior { return .regressed }
                else { return .same }
            }
        }

        enum Trend {
            case improved, regressed, same, new
        }
    }

    private var exerciseProgressData: [MuscleGroup: [ExerciseProgress]] {
        var thisWeekMaxes: [String: (weight: Double, muscleGroup: MuscleGroup, isAssisted: Bool)] = [:]
        var priorMaxes: [String: Double] = [:]

        for session in last7DaysSessions {
            for exercise in session.exercises {
                let isAssisted = PRCalculator.isAssistedExercise(exercise.exerciseName)
                let weights = exercise.sets.map(\.weight).filter { $0 > 0 }
                guard !weights.isEmpty else { continue }

                let best = isAssisted ? weights.min()! : weights.max()!

                if let existing = thisWeekMaxes[exercise.exerciseName] {
                    if isAssisted {
                        if best < existing.weight {
                            thisWeekMaxes[exercise.exerciseName] = (best, exercise.muscleGroup, isAssisted)
                        }
                    } else {
                        if best > existing.weight {
                            thisWeekMaxes[exercise.exerciseName] = (best, exercise.muscleGroup, isAssisted)
                        }
                    }
                } else {
                    thisWeekMaxes[exercise.exerciseName] = (best, exercise.muscleGroup, isAssisted)
                }
            }
        }

        for session in priorSessions {
            for exercise in session.exercises {
                let isAssisted = PRCalculator.isAssistedExercise(exercise.exerciseName)
                let weights = exercise.sets.map(\.weight).filter { $0 > 0 }
                guard !weights.isEmpty else { continue }

                let best = isAssisted ? weights.min()! : weights.max()!

                if let existing = priorMaxes[exercise.exerciseName] {
                    if isAssisted {
                        if best < existing { priorMaxes[exercise.exerciseName] = best }
                    } else {
                        if best > existing { priorMaxes[exercise.exerciseName] = best }
                    }
                } else {
                    priorMaxes[exercise.exerciseName] = best
                }
            }
        }

        var grouped: [MuscleGroup: [ExerciseProgress]] = [:]

        for (name, data) in thisWeekMaxes {
            let progress = ExerciseProgress(
                exerciseName: name,
                muscleGroup: data.muscleGroup,
                thisWeekBest: data.weight,
                priorBest: priorMaxes[name],
                isAssisted: data.isAssisted
            )
            grouped[data.muscleGroup, default: []].append(progress)
        }

        for key in grouped.keys {
            grouped[key]?.sort { $0.exerciseName < $1.exerciseName }
        }

        return grouped
    }

    private var strengthProgress: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strength Progress")
                .font(.headline)
                .foregroundColor(.white)

            let data = exerciseProgressData
            if data.isEmpty {
                Text("No exercises recorded this week")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                let unit = AppSettings.shared.preferredUnit.rawValue
                let sortedGroups = data.keys.sorted { $0.rawValue < $1.rawValue }

                ForEach(sortedGroups, id: \.self) { muscleGroup in
                    if let exercises = data[muscleGroup] {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(muscleGroupColors[muscleGroup] ?? .blue)
                                    .frame(width: 8, height: 8)
                                Text(muscleGroup.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(muscleGroupColors[muscleGroup] ?? .blue)
                            }

                            ForEach(exercises) { exercise in
                                HStack {
                                    Text(exercise.exerciseName)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Spacer()

                                    exerciseTrendView(exercise: exercise, unit: unit)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
    }

    @ViewBuilder
    private func exerciseTrendView(exercise: ExerciseProgress, unit: String) -> some View {
        let thisWeek = formatWeight(exercise.thisWeekBest)

        switch exercise.trend {
        case .new:
            Text("\(thisWeek) \(unit)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("NEW")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)

        case .improved:
            let prior = formatWeight(exercise.priorBest ?? 0)
            Text("\(prior) \u{2192} \(thisWeek) \(unit)")
                .font(.subheadline)
                .foregroundColor(.white)
            Image(systemName: "arrow.up")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)

        case .regressed:
            let prior = formatWeight(exercise.priorBest ?? 0)
            Text("\(prior) \u{2192} \(thisWeek) \(unit)")
                .font(.subheadline)
                .foregroundColor(.white)
            Image(systemName: "arrow.down")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)

        case .same:
            let prior = formatWeight(exercise.priorBest ?? 0)
            Text("\(prior) \u{2192} \(thisWeek) \(unit)")
                .font(.subheadline)
                .foregroundColor(.white)
            Image(systemName: "minus")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }

    // MARK: - Rest Day Streak Warning

    private var consecutiveRestDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        for offset in 0..<30 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let hasWorkout = sessions.contains { session in
                session.isCompleted && calendar.isDate(session.date, inSameDayAs: day)
            }
            if hasWorkout { break }
            streak += 1
        }
        return streak
    }

    private var restDayWarning: some View {
        Group {
            if consecutiveRestDays >= 3 {
                HStack(spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .font(.title3)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(consecutiveRestDays) days rest")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("Ready to get back at it?")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange.opacity(0.6))
                }
                .padding(16)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Weekly Duration Summary

    private var weeklyTotalDuration: Int {
        last7DaysSessions.reduce(0) { $0 + $1.duration }
    }

    private var weeklyAvgDuration: Int {
        guard !last7DaysSessions.isEmpty else { return 0 }
        return weeklyTotalDuration / last7DaysSessions.count
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var weeklyDurationSummary: some View {
        Group {
            if !last7DaysSessions.isEmpty {
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                        Text(formatDuration(weeklyTotalDuration))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 40)
                        .background(Color.gray.opacity(0.3))

                    VStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text(formatDuration(weeklyAvgDuration))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Avg / Session")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 40)
                        .background(Color.gray.opacity(0.3))

                    VStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                            .foregroundColor(.purple)
                        Text("\(last7DaysSessions.reduce(0) { $0 + $1.exercises.count })")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Exercises")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Top Set Highlights

    private struct TopSet: Identifiable {
        let id = UUID()
        let exerciseName: String
        let weight: Double
        let reps: Int
        let date: Date
        let muscleGroup: MuscleGroup
    }

    private var topSetHighlightsData: [TopSet] {
        let calendar = Calendar.current
        var topPerSession: [Date: TopSet] = [:]

        for session in last7DaysSessions {
            let sessionDay = calendar.startOfDay(for: session.date)
            for exercise in session.exercises {
                let isAssisted = PRCalculator.isAssistedExercise(exercise.exerciseName)
                if isAssisted { continue }
                for set in exercise.sets where set.weight > 0 {
                    if let existing = topPerSession[sessionDay] {
                        if set.weight > existing.weight {
                            topPerSession[sessionDay] = TopSet(
                                exerciseName: exercise.exerciseName,
                                weight: set.weight,
                                reps: set.reps,
                                date: session.date,
                                muscleGroup: exercise.muscleGroup
                            )
                        }
                    } else {
                        topPerSession[sessionDay] = TopSet(
                            exerciseName: exercise.exerciseName,
                            weight: set.weight,
                            reps: set.reps,
                            date: session.date,
                            muscleGroup: exercise.muscleGroup
                        )
                    }
                }
            }
        }

        return topPerSession.values.sorted { $0.date > $1.date }
    }

    private var topSetHighlights: some View {
        Group {
            let highlights = topSetHighlightsData
            if !highlights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Sets This Week")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(highlights) { topSet in
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                                .font(.subheadline)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(topSet.exerciseName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                Text(topSet.date.formatted(.dateTime.weekday(.wide)))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text("\(formatWeight(topSet.weight))\(AppSettings.shared.preferredUnit.rawValue) x \(topSet.reps)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(muscleGroupColors[topSet.muscleGroup] ?? .blue)
                        }
                        .padding(12)
                        .background(Color.yellow.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Section 4: Training Gaps

    private var untrainedMuscleGroups: [MuscleGroup] {
        let trainedGroups = Set(weeklySetsByMuscle.map(\.muscleGroup))
        return MuscleGroup.selectableCases.filter { !trainedGroups.contains($0) }
    }

    private var trainingGaps: some View {
        Group {
            if !untrainedMuscleGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Training Gaps")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(untrainedMuscleGroups, id: \.self) { muscleGroup in
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.subheadline)

                            Text("You haven't trained \(muscleGroup.rawValue) this week")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 24))
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [color.opacity(0.2), color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}
