import SwiftUI
import SwiftData

struct ExerciseCard: View {
    let exercise: ExerciseLog
    var previousSets: [SetEntry] = []
    let isSelected: Bool
    var loggerContent: AnyView?
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    private var unitLabel: String {
        settings.preferredUnit.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.ironInk)

                Spacer()

                NavigationLink {
                    ExerciseProgressView(
                        exerciseName: exercise.exerciseName,
                        muscleGroup: exercise.muscleGroup
                    )
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(.ironPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View exercise history")

                Text(exercise.muscleGroup.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.ironPrimary.opacity(0.3))
                    .foregroundColor(.ironPrimary)
                    .cornerRadius(8)
            }

            if PRCalculator.isAssistedExercise(exercise.exerciseName) {
                Text("↓ Lower is better")
                    .font(.caption2)
                    .foregroundColor(.ironSuccess)
            }

            if exercise.sets.isEmpty {
                Text("No sets logged yet")
                    .font(.subheadline)
                    .foregroundColor(.ironMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.ironMuted.opacity(0.1))
                    .cornerRadius(12)
            } else {
                setsTable
            }

            if !previousSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Session Summary")
                        .font(.caption)
                        .foregroundColor(.ironMuted)

                    previousSessionSummary
                }
            }

            if let loggerContent {
                Divider()
                    .background(Color.ironMuted.opacity(0.3))

                loggerContent
            }
        }
        .padding(16)
        .background(isSelected ? Color.ironPrimary.opacity(0.1) : Color.ironMuted.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.ironPrimary : Color.clear, lineWidth: 2)
        )
    }

    private var setsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Set")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 50, alignment: .center)
                    .foregroundColor(.ironMuted)

                Text("Weight")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 110, alignment: .center)
                    .foregroundColor(.ironMuted)

                Text("Reps")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .center)
                    .foregroundColor(.ironMuted)

                Spacer()

                Text("")
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .background(Color.ironMuted.opacity(0.2))

            ForEach(numberedSets, id: \.set.id) { item in
                HStack {
                    Text(item.displayNumber)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 50, alignment: .center)
                        .foregroundColor(.ironMuted)

                    Text(setWeightLabel(item.set))
                        .font(.subheadline)
                        .frame(width: 110, alignment: .center)
                        .foregroundColor(.ironInk)

                    Text("\(item.set.reps)")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .center)
                        .foregroundColor(.ironInk)

                    Spacer()

                    if item.set.isPR {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.ironPR)
                            .frame(width: 44, alignment: .trailing)
                    } else {
                        Text("")
                            .frame(width: 44)
                    }
                }
                .padding(.vertical, 8)
                .background(item.set.isPR ? Color.ironPR.opacity(0.1) : Color.clear)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ironMuted.opacity(0.3), lineWidth: 1)
        )
    }

    private var numberedSets: [(displayNumber: String, set: SetEntry)] {
        var nextSetNumber = 1

        return exercise.sets
            .sorted { $0.timestamp < $1.timestamp }
            .map { set in
                let startNumber = nextSetNumber
                nextSetNumber += set.setCount

                if set.setCount > 1 {
                    return ("\(startNumber)-\(nextSetNumber - 1)", set)
                }

                return ("\(startNumber)", set)
            }
    }

    private var previousSessionSummary: some View {
        let totalSets = previousSets.reduce(0) { $0 + $1.setCount }
        let totalReps = previousSets.reduce(0) { $0 + ($1.reps * $1.setCount) }
        let assisted = PRCalculator.isAssistedExercise(exercise.exerciseName)
        let bestWeight = assisted
            ? (previousSets.map(\.weight).min() ?? 0)
            : (previousSets.map(\.weight).max() ?? 0)
        let hasPR = previousSets.contains { $0.isPR }

        return HStack(spacing: 16) {
            SummaryItem(
                icon: "figure.strengthtraining.traditional",
                value: "\(totalSets)",
                label: totalSets == 1 ? "set" : "sets"
            )

            SummaryItem(
                icon: "repeat",
                value: "\(totalReps)",
                label: totalReps == 1 ? "rep" : "reps"
            )

            SummaryItem(
                icon: "scalemass",
                value: "\(formatWeight(bestWeight))\(unitLabel)",
                label: assisted ? "min" : "max"
            )

            if hasPR {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.ironPR)
                        Text("PR achieved!")
                        .font(.caption)
                        .foregroundColor(.ironPR)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.ironPR.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.ironMuted.opacity(0.05))
        .cornerRadius(8)
    }

    private func setWeightLabel(_ set: SetEntry) -> String {
        let singleArmSuffix = set.isSingleArm ? " SA" : ""
        return "\(formatWeight(set.weight))\(unitLabel)\(singleArmSuffix)"
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.ironMuted.opacity(0.5))

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.ironInk)

            Text(label)
                .font(.caption2)
                .foregroundColor(.ironMuted)
        }
    }
}
