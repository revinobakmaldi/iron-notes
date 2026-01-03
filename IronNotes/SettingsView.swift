import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    
    @State private var selectedMuscleGroup = MuscleGroup.CHEST
    @State private var showAddExercise = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Form {
                Section {
                    HStack {
                        Text("Rest Timer Duration")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(settings.restTimerDuration)s")
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("30s")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: Binding(
                                get: { Double(settings.restTimerDuration) },
                                set: { 
                                    settings.restTimerDuration = Int($0)
                                    settings.saveSettings()
                                }
                            ), in: 30...300, step: 10)
                            
                            Text("5m")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Timer")
                        .foregroundColor(.white)
                }
                
                Section {
                    Picker("Weight Unit", selection: Binding(
                        get: { settings.preferredUnit },
                        set: { 
                            settings.preferredUnit = $0
                            settings.saveSettings()
                        }
                    )) {
                        ForEach(AppSettings.WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.uppercased()).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .foregroundColor(.white)
                } header: {
                    Text("Units")
                        .foregroundColor(.white)
                }
                
                Section {
                    HStack {
                        Picker("Muscle Group", selection: $selectedMuscleGroup) {
                            ForEach(MuscleGroup.allCases, id: \.self) { group in
                                Text(group.rawValue).tag(group)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button(action: { showAddExercise = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    
                    masterExercisesList(for: selectedMuscleGroup)
                } header: {
                    Text("Master Exercises")
                        .foregroundColor(.white)
                }
                
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.white)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Built with")
                            .foregroundColor(.white)
                        Spacer()
                        Text("SwiftUI + SwiftData")
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("About")
                        .foregroundColor(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddExercise) {
            NewExerciseSheet(muscleGroup: selectedMuscleGroup)
        }
    }
    
    @ViewBuilder
    private func masterExercisesList(for muscleGroup: MuscleGroup) -> some View {
        let exercises = settings.getExercises(for: muscleGroup)

        if exercises.isEmpty {
            Text("No exercises for \(muscleGroup.rawValue)")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if exercises.count <= 4 {
            VStack(spacing: 12) {
                ForEach(exercises) { exercise in
                    exerciseRow(exercise: exercise, muscleGroup: muscleGroup)
                }
            }
            .padding(.vertical, 8)
        } else {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(exercises) { exercise in
                            exerciseRow(exercise: exercise, muscleGroup: muscleGroup)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 250)
            }
        }
    }

    private func exerciseRow(exercise: MasterExercise, muscleGroup: MuscleGroup) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
            }

            Spacer()

            Button(action: {
                settings.removeMasterExercise(exercise, from: muscleGroup)
                HapticManager.light()
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(8)
    }
}