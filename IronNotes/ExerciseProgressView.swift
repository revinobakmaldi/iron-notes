import SwiftUI
import SwiftData
import Charts

struct ExerciseProgressView: View {
    let exerciseName: String
    let muscleGroup: MuscleGroup

    @Environment(AppSettings.self) private var settings
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    private var unitLabel: String {
        settings.preferredUnit.rawValue
    }

    private var completedExerciseSessions: [ExerciseSessionProgress] {
        sessions
            .filter { $0.isCompleted || !$0.exercises.isEmpty }
            .compactMap { session in
                let matchingExercises = session.exercises.filter { $0.exerciseName == exerciseName }
                let sets = matchingExercises.flatMap(\.sets)
                guard !sets.isEmpty else { return nil }

                return ExerciseSessionProgress(
                    date: session.date,
                    sets: sets.sorted { $0.timestamp < $1.timestamp },
                    isAssisted: PRCalculator.isAssistedExercise(exerciseName)
                )
            }
            .sorted { $0.date < $1.date }
    }

    private var allSets: [SetEntry] {
        completedExerciseSessions.flatMap(\.sets)
    }

    private var bestSet: SetEntry? {
        let assisted = PRCalculator.isAssistedExercise(exerciseName)
        return allSets
            .filter { $0.weight > 0 && $0.reps > 0 }
            .sorted { first, second in
                assisted ? first.estimated1RM < second.estimated1RM : first.estimated1RM > second.estimated1RM
            }
            .first
    }

    private var prSets: [SetEntry] {
        allSets
            .filter(\.isPR)
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var recentSessions: [ExerciseSessionProgress] {
        Array(completedExerciseSessions.reversed().prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if completedExerciseSessions.isEmpty {
                    emptyState
                } else {
                    statsGrid
                    oneRepMaxChart
                    volumeChart
                    recentHistory
                    prHistory
                }
            }
            .padding()
        }
        .background(Color.ironBackground)
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.ironPrimary)

                Text(muscleGroup.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.ironPrimary)
            }

            Text(exerciseName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ironInk)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52))
                .foregroundColor(.ironMuted)

            Text("No History Yet")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.ironInk)

            Text("Log this exercise to see progress over time.")
                .font(.subheadline)
                .foregroundColor(.ironMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ExerciseProgressStatCard(
                icon: "calendar",
                title: "Sessions",
                value: "\(completedExerciseSessions.count)",
                color: .ironPrimary
            )

            ExerciseProgressStatCard(
                icon: "number",
                title: "Total Sets",
                value: "\(allSets.reduce(0) { $0 + $1.setCount })",
                color: .ironSuccess
            )

            ExerciseProgressStatCard(
                icon: "scalemass",
                title: PRCalculator.isAssistedExercise(exerciseName) ? "Best Assist" : "Best Set",
                value: bestSet.map { "\(formatWeight($0.weight))\(unitLabel) x \($0.reps)" } ?? "-",
                color: .ironAccent
            )

            ExerciseProgressStatCard(
                icon: "star.fill",
                title: "PRs",
                value: "\(prSets.count)",
                color: .ironPR
            )
        }
    }

    private var oneRepMaxChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated 1RM")
                .font(.headline)
                .foregroundColor(.ironInk)

            Chart(completedExerciseSessions) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Estimated 1RM", item.bestEstimated1RM)
                )
                .foregroundStyle(Color.ironPrimary)

                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Estimated 1RM", item.bestEstimated1RM)
                )
                .foregroundStyle(Color.ironPrimary)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(formatWeight(weight))\(unitLabel)")
                        }
                    }
                }
            }
            .frame(height: 220)
        }
        .padding(16)
        .background(Color.ironMuted.opacity(0.1))
        .cornerRadius(12)
    }

    private var volumeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Volume")
                .font(.headline)
                .foregroundColor(.ironInk)

            Chart(completedExerciseSessions) { item in
                BarMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.totalVolume)
                )
                .foregroundStyle(Color.ironSuccess)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let volume = value.as(Double.self) {
                            Text(formatWeight(volume))
                        }
                    }
                }
            }
            .frame(height: 220)
        }
        .padding(16)
        .background(Color.ironMuted.opacity(0.1))
        .cornerRadius(12)
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent History")
                .font(.headline)
                .foregroundColor(.ironInk)

            ForEach(recentSessions) { session in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(session.date, format: .dateTime.month(.abbreviated).day().year())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ironInk)

                        Spacer()

                        Text("\(session.totalSets) sets")
                            .font(.caption)
                            .foregroundColor(.ironMuted)
                    }

                    Text(session.setSummary(unit: unitLabel, formatWeight: formatWeight))
                        .font(.caption)
                        .foregroundColor(.ironMuted)
                }
                .padding(12)
                .background(Color.ironMuted.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    private var prHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PR History")
                .font(.headline)
                .foregroundColor(.ironInk)

            if prSets.isEmpty {
                Text("No PRs recorded for this exercise yet.")
                    .font(.subheadline)
                    .foregroundColor(.ironMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .background(Color.ironMuted.opacity(0.08))
                    .cornerRadius(10)
            } else {
                ForEach(prSets.prefix(6)) { set in
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.ironPR)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(formatWeight(set.weight))\(unitLabel) x \(set.reps)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.ironInk)

                            Text(set.timestamp, format: .dateTime.month(.abbreviated).day().year())
                                .font(.caption)
                                .foregroundColor(.ironMuted)
                        }

                        Spacer()

                        Text("\(formatWeight(set.estimated1RM))\(unitLabel)")
                            .font(.caption)
                            .foregroundColor(.ironPR)
                    }
                    .padding(12)
                    .background(Color.ironPR.opacity(0.08))
                    .cornerRadius(10)
                }
            }
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

private struct ExerciseSessionProgress: Identifiable {
    let id = UUID()
    let date: Date
    let sets: [SetEntry]
    let isAssisted: Bool

    var totalSets: Int {
        sets.reduce(0) { $0 + $1.setCount }
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps) * Double($1.setCount)) }
    }

    var bestEstimated1RM: Double {
        let estimates = sets.map(\.estimated1RM).filter { $0 > 0 }
        return isAssisted ? (estimates.min() ?? 0) : (estimates.max() ?? 0)
    }

    func setSummary(unit: String, formatWeight: (Double) -> String) -> String {
        sets.map { set in
            let countPrefix = set.setCount > 1 ? "\(set.setCount)x " : ""
            let singleArmSuffix = set.isSingleArm ? " SA" : ""
            return "\(countPrefix)\(formatWeight(set.weight))\(unit) x \(set.reps)\(singleArmSuffix)"
        }
        .joined(separator: " · ")
    }
}

private struct ExerciseProgressStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.ironMuted)

                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.ironInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.ironMuted.opacity(0.1))
        .cornerRadius(10)
    }
}
