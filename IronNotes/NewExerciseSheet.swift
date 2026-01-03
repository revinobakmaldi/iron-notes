import SwiftUI

struct NewExerciseSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    
    let muscleGroup: MuscleGroup

    @State private var exerciseName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                        .autocapitalization(.none)
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
            defaultWeight: 0,
            defaultReps: 0
        )

        settings.addMasterExercise(newExercise, for: muscleGroup)

        HapticManager.success()
        dismiss()
    }
}
