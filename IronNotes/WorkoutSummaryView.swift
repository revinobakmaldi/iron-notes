import SwiftUI

struct WorkoutSummaryView: View {
    let session: WorkoutSession
    let onComplete: () -> Void

    var totalSets: Int {
        session.exercises.reduce(0) { $0 + $1.sets.count }
    }

    var totalVolume: Double {
        session.exercises.reduce(0.0) { sum, exercise in
            sum + exercise.sets.reduce(0.0) { setSum, set in
                setSum + (set.weight * Double(set.reps))
            }
        }
    }

    var muscleGroups: [MuscleGroup] {
        Array(Set(session.exercises.map { $0.muscleGroup }))
    }

    var prCount: Int {
        session.exercises.reduce(0) { $0 + $1.sets.filter { $0.isPR }.count }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text("Workout Completed!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 16) {
                            SummaryRow(
                                icon: "figure.strengthtraining.traditional",
                                title: "Exercises",
                                value: "\(session.exercises.count)"
                            )

                            SummaryRow(
                                icon: "number",
                                title: "Total Sets",
                                value: "\(totalSets)"
                            )

                            SummaryRow(
                                icon: "scalemass",
                                title: "Total Volume",
                                value: "\(Int(totalVolume))kg"
                            )

                            if prCount > 0 {
                                SummaryRow(
                                    icon: "star.fill",
                                    title: "PRs Achieved",
                                    value: "\(prCount)",
                                    color: .yellow
                                )
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Muscle Groups")
                                .font(.headline)
                                .foregroundColor(.white)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(muscleGroups, id: \.self) { group in
                                    Text(group.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)

                        VStack(spacing: 8) {
                            Text(formatDuration(session.duration))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Duration")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        Button(action: {
                            HapticManager.success()
                            onComplete()
                        }) {
                            Text("Done")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        HapticManager.light()
                        onComplete()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
