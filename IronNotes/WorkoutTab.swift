import SwiftUI
import SwiftData

struct WorkoutTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var showNewWorkout = false
    @State private var sessionToDelete: WorkoutSession?
    @State private var showDeleteAlert = false

    private var groupedSessions: [(key: String, sessions: [WorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: sessions) { session -> String in
            formatter.string(from: session.date)
        }

        return grouped.map { (key: $0.key, sessions: $0.value) }
            .sorted { first, second in
                guard let d1 = first.sessions.first?.date, let d2 = second.sessions.first?.date else { return false }
                return d1 > d2
            }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Button(action: { showNewWorkout = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Start New Workout")
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

                        if sessions.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray)
                                Text("No Workouts Yet")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Start your first workout by tapping the button above")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            VStack(spacing: 24) {
                                ForEach(groupedSessions, id: \.key) { group in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(group.key)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)

                                        ForEach(group.sessions) { session in
                                            SessionCard(session: session) {
                                                sessionToDelete = session
                                                showDeleteAlert = true
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("IronNotes")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
        .alert("Delete Workout", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
        } message: {
            Text("Delete this workout? This action cannot be undone.")
        }
        .sheet(isPresented: $showNewWorkout) {
            NewWorkoutSheet(isPresented: $showNewWorkout)
        }
    }

    private func deleteSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        sessionToDelete = nil
        HapticManager.success()
    }
}

struct SessionCard: View {
    let session: WorkoutSession
    let onDelete: () -> Void

    private let muscleGroupColors: [MuscleGroup: Color] = [
        .CHEST: Color(red: 0.95, green: 0.45, blue: 0.35),
        .BACK: Color(red: 0.35, green: 0.55, blue: 0.9),
        .LEGS: Color(red: 0.35, green: 0.8, blue: 0.45),
        .SHOULDERS: Color(red: 0.95, green: 0.65, blue: 0.25),
        .ARMS: Color(red: 0.75, green: 0.4, blue: 0.8),
        .CORE: Color(red: 0.35, green: 0.7, blue: 0.85)
    ]

    private var totalSets: Int {
        session.exercises.reduce(0) { $0 + $1.sets.count }
    }

    private var uniqueMuscleGroups: [MuscleGroup] {
        var seen = Set<MuscleGroup>()
        return session.exercises.compactMap { exercise in
            seen.insert(exercise.muscleGroup).inserted ? exercise.muscleGroup : nil
        }
    }

    private var formattedDuration: String {
        let minutes = session.duration / 60
        if minutes < 1 { return "<1m" }
        if minutes >= 60 {
            let hours = minutes / 60
            let remaining = minutes % 60
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    var body: some View {
        NavigationLink(destination: ActiveWorkoutView(session: session)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(session.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(session.date, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                HStack(spacing: 4) {
                    Text("\(session.exercises.count) exercises")
                    Text("·").foregroundColor(.gray.opacity(0.6))
                    Text("\(totalSets) sets")
                    if session.duration > 0 {
                        Text("·").foregroundColor(.gray.opacity(0.6))
                        Text(formattedDuration)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.gray)

                if !uniqueMuscleGroups.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(uniqueMuscleGroups, id: \.self) { group in
                            Text(group.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(muscleGroupColors[group] ?? .blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background((muscleGroupColors[group] ?? .blue).opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }

                if !session.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(session.exercises.prefix(3)) { exercise in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(muscleGroupColors[exercise.muscleGroup] ?? .blue)
                                    .frame(width: 6, height: 6)
                                Text(exercise.exerciseName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        if session.exercises.count > 3 {
                            Text("+ \(session.exercises.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .onLongPressGesture {
                HapticManager.medium()
                onDelete()
            }
        }
    }
}

struct NewWorkoutSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button("Start Fresh") {
                        startWorkout(cloneLast: false)
                    }
                    .foregroundColor(.blue)

                    Button("Clone Last Workout") {
                        startWorkout(cloneLast: true)
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(Color.black)
        }
    }

    private func startWorkout(cloneLast: Bool) {
        let session: WorkoutSession

        if cloneLast {
            session = WorkoutSession.cloneLastSession(context: modelContext)
        } else {
            session = WorkoutSession()
        }

        modelContext.insert(session)
        isPresented = false
        dismiss()
    }
}
