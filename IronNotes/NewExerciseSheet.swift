import SwiftUI

struct NewExerciseSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    
    let muscleGroup: MuscleGroup
    
    @State private var exerciseName = ""
    @State private var defaultWeight: Double = 0
    @State private var defaultReps: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                        .autocapitalization(.none)
                    
                    HStack {
                        Text("Default")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            HapticManager.light()
                            defaultWeight = max(defaultWeight - 2.5, 0)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .frame(minWidth: 36, minHeight: 36)
                        
                        Text(String(format: "%.1f", defaultWeight))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 80)
                        
                        Button(action: {
                            HapticManager.light()
                            defaultWeight += 2.5
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .frame(minWidth: 36, minHeight: 36)
                        
                        Text("kg")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            HapticManager.light()
                            defaultReps = max(defaultReps - 1, 1)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .frame(minWidth: 36, minHeight: 36)
                        
                        Text("\(defaultReps)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 80)
                        
                        Button(action: {
                            HapticManager.light()
                            defaultReps += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .frame(minWidth: 36, minHeight: 36)
                        
                        Text("reps")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Add to Master")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveExercise() {
        let newExercise = MasterExercise(
            name: exerciseName.trimmingCharacters(in: .whitespaces),
            defaultWeight: defaultWeight,
            defaultReps: defaultReps
        )
        
        settings.addMasterExercise(newExercise, for: muscleGroup)
        
        HapticManager.success()
        dismiss()
    }
}
