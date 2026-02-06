import SwiftUI

struct ExerciseCard: View {
    let exercise: ExerciseLog
    var previousSets: [SetEntry] = []
    let isSelected: Bool
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

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
                    .frame(width: 100, alignment: .center)
                    .foregroundColor(.gray)

                Text("Reps")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .center)
                    .foregroundColor(.gray)

                Spacer()

                Text("")
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))

            ForEach(exercise.sets.sorted(by: { $0.timestamp < $1.timestamp })) { set in
                HStack {
                    Text("\(Int(set.weight))kg")
                        .font(.subheadline)
                        .frame(width: 100, alignment: .center)
                        .foregroundColor(.white)

                    Text("\(set.reps)")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .center)
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
        let totalSets = previousSets.count
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
                icon: "scalemass",
                value: "\(Int(bestWeight))kg",
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