import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputText = ""
    @State private var showRestTimer = false
    @State private var showAddExercise = false
    @State private var showFinishWorkout = false
    @FocusState private var inputFocused: Bool
    
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
                                    
                                    ExerciseCard(exercise: exercise, previousSets: previousSets)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    SmartParserInput(
                        inputText: $inputText,
                        onSubmit: handleInputSubmit
                    )
                }
            }
            
            if showRestTimer {
                RestTimerView(duration: AppSettings.shared.restTimerDuration) {
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
    
    private func handleInputSubmit() {
        guard let parsedSet = WorkoutParser.parse(inputText) else {
            HapticManager.error()
            return
        }
        
        guard let exercise = session.exercises.first else {
            HapticManager.error()
            return
        }
        
        let setEntry = SetEntry(
            weight: parsedSet.weight,
            reps: parsedSet.reps,
            setCount: exercise.sets.count + 1,
            isSingleArm: parsedSet.isSingleArm
        )
        
        setEntry.exercise = exercise
        exercise.sets.append(setEntry)
        
        PRCalculator.checkAndMarkPR(
            for: setEntry,
            exerciseName: exercise.exerciseName,
            context: modelContext
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
    @Environment(\.dismiss) private var dismiss
    
    @State private var exerciseName = ""
    @State private var selectedMuscleGroup = MuscleGroup.CHEST
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                    
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addExercise()
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addExercise() {
        let exercise = ExerciseLog(
            name: exerciseName.trimmingCharacters(in: .whitespaces),
            muscleGroup: selectedMuscleGroup
        )
        exercise.session = session
        session.exercises.append(exercise)
        
        HapticManager.success()
        dismiss()
    }
}