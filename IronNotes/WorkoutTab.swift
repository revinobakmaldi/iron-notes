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
                Color.ironBackground.ignoresSafeArea()

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
                            .foregroundColor(.ironOnPrimary)
                            .padding()
                            .background(Color.ironPrimary)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)

                        if sessions.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 80))
                                    .foregroundColor(.ironMuted)
                                Text("No Workouts Yet")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.ironInk)
                                Text("Start your first workout by tapping the button above")
                                    .font(.subheadline)
                                    .foregroundColor(.ironMuted)
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
                                            .foregroundColor(.ironInk)

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
                            .foregroundColor(.ironPrimary)
                        Text("IronNotes")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.ironInk)
                    }
                }
            }
            .background(Color.ironBackground)
            .preferredColorScheme(.light)
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
        .CHEST: Color(red: 0.73, green: 0.22, blue: 0.06),
        .BACK: Color(red: 0.18, green: 0.27, blue: 0.31),
        .LEGS: Color(red: 0.34, green: 0.39, blue: 0.20),
        .SHOULDERS: Color(red: 0.66, green: 0.47, blue: 0.20),
        .ARMS: Color(red: 0.36, green: 0.30, blue: 0.50),
        .CORE: Color(red: 0.48, green: 0.34, blue: 0.23)
    ]

    private var totalSets: Int {
        session.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + $1.setCount }
        }
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
                        .foregroundColor(.ironInk)

                    Spacer()

                    Text(session.date, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundColor(.ironMuted)

                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.ironSuccess)
                    }
                }

                HStack(spacing: 4) {
                    Text("\(session.exercises.count) exercises")
                    Text("·").foregroundColor(.ironMuted.opacity(0.6))
                    Text("\(totalSets) sets")
                    if session.duration > 0 {
                        Text("·").foregroundColor(.ironMuted.opacity(0.6))
                        Text(formattedDuration)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.ironMuted)

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
                                    .foregroundColor(.ironMuted)
                            }
                        }

                        if session.exercises.count > 3 {
                            Text("+ \(session.exercises.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.ironMuted.opacity(0.6))
                        }
                    }
                }
            }
            .padding()
            .background(Color.ironMuted.opacity(0.1))
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
    
    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button("Start Fresh") {
                        startWorkout(cloneLast: false, customDate: nil)
                    }
                    .foregroundColor(.ironPrimary)

                    Button("Clone Last Workout") {
                        startWorkout(cloneLast: true, customDate: nil)
                    }
                    .foregroundColor(.ironPrimary)
                    
                    Button("Backdate Session") {
                        showDatePicker = true
                    }
                    .foregroundColor(.ironAccent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ironBackground)
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate) { startDate, duration in
                    startWorkout(cloneLast: false, customDate: startDate, customDuration: duration)
                }
            }
        }
    }

    private func startWorkout(cloneLast: Bool, customDate: Date?, customDuration: Int = 0) {
        let session: WorkoutSession

        if cloneLast {
            session = WorkoutSession.cloneLastSession(context: modelContext)
        } else {
            session = WorkoutSession()
        }
        
        // Override date if backdated
        if let date = customDate {
            session.date = date
        }
        
        // Set duration if backdated - but don't auto-complete anymore
        // User can still add exercises before finishing
        if customDuration > 0 {
            session.duration = customDuration
            // Removed: session.isCompleted = true
            // User will manually finish when done adding exercises
        }

        modelContext.insert(session)
        isPresented = false
        dismiss()
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    let onConfirm: (Date, Int) -> Void
    
    @State private var endDate: Date = Date().addingTimeInterval(3600) // +1 hour default
    
    private var durationMinutes: Int {
        Int(endDate.timeIntervalSince(selectedDate)) / 60
    }
    
    private var formattedDuration: String {
        let mins = durationMinutes
        if mins < 0 { return "Invalid" }
        let h = mins / 60
        let m = mins % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Start Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("START")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.ironPrimary)
                    
                    DatePicker(
                        "Start",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .padding()
                    .background(Color.ironMuted.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // End Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("END")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.ironAccent)
                    
                    DatePicker(
                        "End",
                        selection: $endDate,
                        in: selectedDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .padding()
                    .background(Color.ironMuted.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Duration display
                HStack {
                    Text("Duration:")
                        .foregroundColor(.ironMuted)
                    Text(formattedDuration)
                        .font(.headline)
                        .foregroundColor(.ironSuccess)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(Color.ironBackground.ignoresSafeArea())
            .navigationTitle("Backdate Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.ironMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        let duration = Int(endDate.timeIntervalSince(selectedDate))
                        onConfirm(selectedDate, duration)
                        dismiss()
                    }
                    .foregroundColor(.ironAccent)
                    .fontWeight(.bold)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
