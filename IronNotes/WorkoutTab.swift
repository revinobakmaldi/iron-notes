import SwiftUI
import SwiftData

struct WorkoutTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var showNewWorkout = false
    @State private var sessionToDelete: WorkoutSession?
    @State private var showDeleteAlert = false

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
                            VStack(spacing: 16) {
                                ForEach(sessions) { session in
                                    SessionCard(session: session) {
                                        sessionToDelete = session
                                        showDeleteAlert = true
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

    var body: some View {
        NavigationLink(destination: ActiveWorkoutView(session: session)) {
            VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(session.date, format: .dateTime.month().day().year())
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

                        Text("\(session.exercises.count) exercises")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if !session.exercises.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(session.exercises.prefix(3)) { exercise in
                                    HStack {
                                        Circle()
                                            .fill(Color.blue)
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
