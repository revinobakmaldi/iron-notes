import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var showRestTimer = false
    @State private var showAddExercise = false
    @State private var showFinishWorkout = false
    @State private var showSummary = false
    @State private var selectedExerciseID: UUID?
    @State private var summaryDismissed = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text(session.date, format: .dateTime.month().day().year())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: {
                                if !session.isCompleted {
                                    showFinishWorkout = true
                                }
                            }) {
                                Text(session.isCompleted ? "Completed" : "Finish")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(session.isCompleted ? Color.gray : Color.blue)
                                    .cornerRadius(10)
                            }
                            .frame(minWidth: 44, minHeight: 44)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)

                        if session.exercises.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No Exercises Yet")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Add your first exercise to start tracking")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(session.exercises) { exercise in
                                    let previousSets = session.getPreviousSessionData(
                                        exerciseName: exercise.exerciseName,
                                        context: modelContext
                                    )
                                    let isSelected = selectedExerciseID == exercise.id

                                    ExerciseCard(
                                        exercise: exercise,
                                        previousSets: previousSets,
                                        isSelected: isSelected
                                    )
                                    .onTapGesture {
                                        if !session.isCompleted {
                                            HapticManager.light()
                                            selectedExerciseID = exercise.id
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if !session.isCompleted {
                        SmartParserInput(
                            exercise: getSelectedExercise(),
                            onLog: handleLog
                        )
                    }
                }
            }

            if showRestTimer {
                RestTimerView(duration: settings.restTimerDuration) {
                    showRestTimer = false
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if selectedExerciseID != nil && !session.isCompleted {
                    Button(action: {
                        if let exercise = getSelectedExercise() {
                            deleteExercise(exercise)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if !session.isCompleted {
                    Button(action: { showAddExercise = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseSheet(session: session)
        }
        .fullScreenCover(isPresented: $showSummary) {
            WorkoutSummaryView(session: session) {
                showSummary = false
            }
        }
        .onChange(of: showSummary) { _, newValue in
            if !newValue && session.isCompleted && !summaryDismissed {
                summaryDismissed = true
                dismiss()
            }
        }
        .alert("Finish Workout", isPresented: $showFinishWorkout) {
            Button("Cancel", role: .cancel) { }
            Button("Finish", role: .destructive) {
                finishWorkout()
            }
        } message: {
            Text("Are you sure you want to finish this workout?")
        }
    }

    private func getSelectedExercise() -> ExerciseLog? {
        guard let selectedID = selectedExerciseID else {
            return session.exercises.first
        }
        return session.exercises.first { $0.id == selectedID }
    }

    private func handleLog(weight: Double, reps: Int, setCount: Int) {
        guard let exercise = getSelectedExercise() else {
            HapticManager.error()
            return
        }

        guard !session.isCompleted else {
            HapticManager.error()
            return
        }

        let setEntry = SetEntry(
            weight: weight,
            reps: reps,
            setCount: setCount,
            isSingleArm: false
        )

        setEntry.exercise = exercise
        exercise.sets.append(setEntry)

        PRCalculator.checkAndMarkPR(
            for: setEntry,
            exerciseName: exercise.exerciseName,
            context: modelContext,
            sessionDate: session.date
        )

        showRestTimer = true
    }

    private func finishWorkout() {
        let endTime = Date()
        let durationInSeconds = Int(endTime.timeIntervalSince(session.date))

        session.duration = durationInSeconds
        session.isCompleted = true

        HapticManager.success()
        showSummary = true
    }

    private func deleteExercise(_ exercise: ExerciseLog) {
        modelContext.delete(exercise)
        HapticManager.success()
    }
}

struct AddExerciseSheet: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMuscleGroup = MuscleGroup.CHEST
    @State private var searchText = ""
    @State private var showAddNewExercise = false

    var filteredExercises: [MasterExercise] {
        let exercises = settings.getExercises(for: selectedMuscleGroup)
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Muscle Group", selection: $selectedMuscleGroup) {
                    ForEach(MuscleGroup.selectableCases, id: \.self) { group in
                        Text(group.rawValue).tag(group)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.gray.opacity(0.05))

                List {
                    if filteredExercises.isEmpty && !searchText.isEmpty {
                        Text("No master exercises for \(selectedMuscleGroup.rawValue)")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if filteredExercises.isEmpty {
                        Text("No exercises found")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(filteredExercises) { exercise in
                            Button(action: {
                                HapticManager.light()
                                addExercise(name: exercise.name, muscleGroup: selectedMuscleGroup)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        if exercise.defaultWeight > 0 {
                                            HStack(spacing: 4) {
                                                Text("\(Int(exercise.defaultWeight))kg")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text("× \(exercise.defaultReps)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 12)
                                .listRowBackground(Color.black)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search exercises")
                .navigationTitle("Add Exercise")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showAddNewExercise = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddNewExercise) {
            NewExerciseSheet(muscleGroup: selectedMuscleGroup)
        }
    }

    private func addExercise(name: String, muscleGroup: MuscleGroup) {
        let exercise = ExerciseLog(
            name: name,
            muscleGroup: muscleGroup
        )
        exercise.session = session
        session.exercises.append(exercise)

        HapticManager.success()
        dismiss()
    }
}