import SwiftUI

struct SmartParserInput: View {
    @Binding var inputText: String
    let selectedExercise: ExerciseLog?
    @FocusState private var isFocused: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let exercise = selectedExercise {
                    Text(exercise.exerciseName)
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("Select an exercise above")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                TextField("Enter workout (e.g., 100kg 10r 3s)", text: $inputText)
                    .focused($isFocused)
                    .foregroundColor(.white)
                    .accentColor(.blue)
                    .onSubmit {
                        handleSubmit()
                    }
                    .onChange(of: inputText) { _, _ in
                        HapticManager.light()
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            
            Button(action: handleSubmit) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(16)
        .background(Color.black)
    }
    
    private func handleSubmit() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else {
            HapticManager.error()
            return
        }
        
        HapticManager.success()
        onSubmit()
        inputText = ""
    }
}