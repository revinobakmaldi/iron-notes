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
                    .foregroundColor(.white)

                Spacer()

                NavigationLink {
                    ExerciseProgressView(
                        exerciseName: exercise.exerciseName,
                        muscleGroup: exercise.muscleGroup
                    )
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View exercise history")

                Text(exercise.muscleGroup.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.3))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }

            if PRCalculator.isAssistedExercise(exercise.exerciseName) {
                Text("↓ Lower is better")
                    .font(.caption2)
                    .foregroundColor(.green)
            }

            if exercise.sets.isEmpty {
                Text("No sets logged yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
                setsTable
            }

            if !previousSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Session Summary")
                        .font(.caption)
                        .foregroundColor(.gray)

                    previousSessionSummary
                }
            }

            if let loggerContent {
                Divider()
                    .background(Color.gray.opacity(0.3))

                loggerContent
            }
        }
        .padding(16)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private var setsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Weight")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 110, alignment: .center)
                    .foregroundColor(.gray)

                Text("Reps")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .center)
                    .foregroundColor(.gray)

                Text("Sets")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 50, alignment: .center)
                    .foregroundColor(.gray)

                Spacer()

                Text("")
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))

            ForEach(exercise.sets.sorted(by: { $0.timestamp < $1.timestamp })) { set in
                HStack {
                    Text(setWeightLabel(set))
                        .font(.subheadline)
                        .frame(width: 110, alignment: .center)
                        .foregroundColor(.white)

                    Text("\(set.reps)")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .center)
                        .foregroundColor(.white)

                    Text("\(set.setCount)")
                        .font(.subheadline)
                        .frame(width: 50, alignment: .center)
                        .foregroundColor(.white)

                    Spacer()

                    if set.isPR {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                            .frame(width: 44, alignment: .trailing)
                    } else {
                        Text("")
                            .frame(width: 44)
                    }
                }
                .padding(.vertical, 8)
                .background(set.isPR ? Color.yellow.opacity(0.1) : Color.clear)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
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
                        .foregroundColor(.yellow)
                        Text("PR achieved!")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
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
                .foregroundColor(.gray.opacity(0.5))

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}
