import SwiftUI

struct SmartParserInput: View {
    @Binding var inputText: String
    @FocusState private var isFocused: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Enter workout (e.g., 100kg 10r 3s)", text: $inputText)
                .focused($isFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .foregroundColor(.white)
                .accentColor(.blue)
                .onSubmit {
                    handleSubmit()
                }
                .onChange(of: inputText) { _, _ in
                    HapticManager.light()
                }
            
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