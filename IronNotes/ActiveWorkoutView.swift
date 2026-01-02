import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    
    @State private var showRestTimer = false
    @State private var showAddExercise = false
    @State private var showFinishWorkout = false
    @State private var selectedExerciseID: UUID?
    
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
                            
                            Button(action: { showFinishWorkout = true }) {
                                Text("Finish")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
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
                                    
                                    Button(action: {
                                        HapticManager.light()
                                        selectedExerciseID = exercise.id
                                    }) {
                                        ExerciseCard(
                                            exercise: exercise,
                                            previousSets: previousSets,
                                            isSelected: isSelected
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    SmartParserInput(
                        exercise: getSelectedExercise(),
                        onLog: handleLog
                    )
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddExercise = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseSheet(session: session)
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
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
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
                                            .foregroundColor(.white)
                                        
                                        if exercise.defaultWeight > 0 {
                                            HStack(spacing: 4) {
                                                Text("\(Int(exercise.defaultWeight))kg")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                Text("× \(exercise.defaultReps)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 12)
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