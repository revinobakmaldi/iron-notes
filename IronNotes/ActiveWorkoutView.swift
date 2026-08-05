import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var showAddExercise = false
    @State private var showFinishWorkout = false
    @State private var showSummary = false
    @State private var selectedExerciseID: UUID?
    @State private var summaryDismissed = false

    var body: some View {
        ZStack {
            Color.ironBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text(session.date, format: .dateTime.month().day().year())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.ironInk)

                            Spacer()

                            if !session.isCompleted {
                                Button(action: {
                                    showFinishWorkout = true
                                }) {
                                    Text("Finish")
                                        .font(.headline)
                                        .foregroundColor(.ironOnPrimary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.ironPrimary)
                                        .cornerRadius(10)
                                }
                                .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)

                        if session.uniqueExercises.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 60))
                                    .foregroundColor(.ironMuted)
                                Text("No Exercises Yet")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.ironInk)
                                Text("Add your first exercise to start tracking")
                                    .font(.subheadline)
                                    .foregroundColor(.ironMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(session.uniqueExercises) { exercise in
                                    let previousSets = session.getPreviousSessionData(
                                        exerciseName: exercise.exerciseName,
                                        context: modelContext
                                    )
                                    let selectedExercise = getSelectedExercise()
                                    let isSelected = selectedExercise?.id == exercise.id
                                    let loggerContent: AnyView? = isSelected && !session.isCompleted
                                        ? AnyView(
                                            SmartParserInput(
                                                exercise: exercise,
                                                previousSets: previousSets,
                                                showsHeader: false,
                                                isEmbedded: true,
                                                onLog: handleLog
                                            )
                                        )
                                        : nil

                                    ExerciseCard(
                                        exercise: exercise,
                                        previousSets: previousSets,
                                        isSelected: isSelected,
                                        loggerContent: loggerContent
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
            }
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if getSelectedExercise() != nil && !session.isCompleted {
                    Button(action: {
                        if let exercise = getSelectedExercise() {
                            deleteExercise(exercise)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.ironDanger)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if !session.isCompleted {
                    Button(action: { showAddExercise = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.ironInk)
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
        .onChange(of: session.uniqueExercises.map(\.id)) { _, exerciseIDs in
            selectedExerciseID = exerciseIDs.last
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
        let exercises = session.uniqueExercises
        guard let selectedID = selectedExerciseID else {
            return exercises.last
        }
        return exercises.first { $0.id == selectedID } ?? exercises.last
    }

    private func getPreviousSetsForSelectedExercise() -> [SetEntry] {
        guard let exercise = getSelectedExercise() else {
            return []
        }

        return session.getPreviousSessionData(
            exerciseName: exercise.exerciseName,
            context: modelContext
        )
    }

    private func handleLog(weight: Double, reps: Int, setCount: Int, isSingleArm: Bool) {
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
            isSingleArm: isSingleArm
        )

        exercise.sets.append(setEntry)

        PRCalculator.checkAndMarkPR(
            for: setEntry,
            exerciseName: exercise.exerciseName,
            context: modelContext,
            sessionDate: session.date
        )

        TimerManager.shared.startTimer(duration: settings.restTimerDuration)
    }

    private func finishWorkout() {
        // Only auto-calculate if duration wasn't manually set
        if session.duration == 0 {
            let endTime = Date()
            let durationInSeconds = Int(endTime.timeIntervalSince(session.date))
            session.duration = durationInSeconds
        }
        
        session.isCompleted = true

        Task {
            try? await HealthSyncManager.shared.sync(
                session: session,
                settings: settings,
                modelContext: modelContext
            )
        }

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
            ZStack {
                Color.ironBackground.ignoresSafeArea()

                VStack(spacing: 18) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.ironPrimary)
                                .padding(.horizontal, 18)
                                .frame(height: 48)
                                .background(Color.ironSurface)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.ironSurfaceMuted, lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .frame(minWidth: 44, minHeight: 44)

                        Spacer()

                        Text("Add Exercise")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.ironInk)

                        Spacer()

                        Button(action: {
                            HapticManager.light()
                            showAddNewExercise = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.ironPrimary)
                                .frame(width: 48, height: 48)
                                .background(Color.ironSurface)
                                .overlay(
                                    Circle()
                                        .stroke(Color.ironSurfaceMuted, lineWidth: 1)
                                )
                                .clipShape(Circle())
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MuscleGroup.selectableCases, id: \.self) { group in
                                MuscleGroupChip(
                                    title: group.rawValue,
                                    isSelected: selectedMuscleGroup == group
                                ) {
                                    HapticManager.light()
                                    selectedMuscleGroup = group
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundColor(.ironMuted)

                        TextField("Search exercises", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.headline)
                            .foregroundColor(.ironInk)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(Color.ironSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.ironSurfaceMuted, lineWidth: 1)
                    )
                    .cornerRadius(20)
                    .padding(.horizontal, 24)

                    Group {
                        if filteredExercises.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.ironMuted)

                                Text(searchText.isEmpty ? "No exercises in \(selectedMuscleGroup.rawValue)" : "No matches")
                                    .font(.headline)
                                    .foregroundColor(.ironInk)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 56)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 10) {
                                    ForEach(filteredExercises) { exercise in
                                        ExercisePickerRow(
                                            exercise: exercise,
                                            unit: settings.preferredUnit.rawValue,
                                            formatWeight: formatWeight
                                        ) {
                                            HapticManager.light()
                                            addExercise(name: exercise.name, muscleGroup: selectedMuscleGroup)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showAddNewExercise) {
            NewExerciseSheet(muscleGroup: selectedMuscleGroup)
        }
        .onAppear {
            settings.ensureDefaultMasterExercises()
        }
    }

    private func addExercise(name: String, muscleGroup: MuscleGroup) {
        let exercise = ExerciseLog(
            name: name,
            muscleGroup: muscleGroup
        )
        session.exercises.append(exercise)

        HapticManager.success()
        dismiss()
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

private struct MuscleGroupChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .ironOnPrimary : .ironPrimary)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(isSelected ? Color.ironPrimary : Color.ironSurface)
                .overlay(
                    Capsule()
                        .stroke(Color.ironSurfaceMuted, lineWidth: isSelected ? 0 : 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

private struct ExercisePickerRow: View {
    let exercise: MasterExercise
    let unit: String
    let formatWeight: (Double) -> String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ironInk)
                        .lineLimit(2)

                    if exercise.defaultWeight > 0 {
                        Text("\(formatWeight(exercise.defaultWeight))\(unit) x \(exercise.defaultReps)")
                            .font(.caption)
                            .foregroundColor(.ironMuted)
                    }
                }

                Spacer(minLength: 12)

                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.ironOnPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.ironPrimary)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.ironSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.ironSurfaceMuted, lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
