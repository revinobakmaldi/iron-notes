import SwiftUI

struct SmartParserInput: View {
    let exercise: ExerciseLog?
    var onLog: (Double, Int, Int) -> Void
    var onToggleTimer: () -> Void = {}

    @State private var weight: Double = 0
    @State private var reps: Int = 0
    @State private var setCount: Int = 1
    @State private var isSingleArm: Bool = false
    @State private var showTextMode: Bool = false
    @State private var inputText = ""
    
    var lastSet: SetEntry? {
        exercise?.sets.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(exercise?.exerciseName ?? "Select Exercise")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: {
                    HapticManager.light()
                    showTextMode.toggle()
                }) {
                    Image(systemName: showTextMode ? "number" : "textformat")
                        .foregroundColor(.gray)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            if showTextMode {
                textModeInput
            } else {
                quickModeInput
            }
        }
        .background(Color.black)
    }
    
    private var textModeInput: some View {
        VStack(spacing: 12) {
            Text("Quick text mode: e.g., 100kg 10r 3s")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 12) {
                TextField("100kg 10r 3s", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button(action: {
                    if let parsed = WorkoutParser.parse(inputText) {
                        onLog(parsed.weight, parsed.reps, parsed.setCount)
                        inputText = ""
                        showTextMode = false
                        HapticManager.success()
                    } else {
                        HapticManager.error()
                    }
                }) {
                    Text("Log")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                Button(action: {
                    showTextMode = false
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var quickModeInput: some View {
        VStack(spacing: 16) {
            if let last = lastSet {
                HStack {
                    Text("Last set:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(Int(last.weight))kg x \(last.reps)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        weight = last.weight
                        reps = last.reps
                        setCount = exercise?.sets.count ?? 0 + 1
                        isSingleArm = last.isSingleArm
                        HapticManager.light()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            VStack(spacing: 12) {
                weightInput
                repsInput
                
                HStack {
                    setNumberDisplay
                    Spacer()
                    isSingleArmToggle
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            logButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }
    
    private var weightInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.light()
                    weight = max(weight - 2.5, 0)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .frame(minWidth: 44, minHeight: 44)

                TextField("0.0", value: $weight, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 120)

                Button(action: {
                    HapticManager.light()
                    weight += 2.5
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .frame(minWidth: 44, minHeight: 44)

                Text("kg")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var repsInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reps")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.light()
                    reps = max(reps - 1, 1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .frame(minWidth: 44, minHeight: 44)

                TextField("0", value: $reps, format: .number)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 80)

                Button(action: {
                    HapticManager.light()
                    reps += 1
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var setNumberDisplay: some View {
        let nextSetNumber = (exercise?.sets.count ?? 0) + 1
        return HStack(spacing: 12) {
            Text("Set #\(nextSetNumber)")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
    
    private var isSingleArmToggle: some View {
        Button(action: {
            HapticManager.light()
            isSingleArm.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: isSingleArm ? "hand.point.left.fill" : "hand.point.left")
                    .foregroundColor(isSingleArm ? .blue : .gray)
                
                Text("Single Arm")
                    .font(.subheadline)
                    .foregroundColor(isSingleArm ? .blue : .gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSingleArm ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .frame(minWidth: 44, minHeight: 44)
    }
    
    private var logButton: some View {
        Button(action: {
            HapticManager.success()
            onLog(weight, reps, setCount)
        }) {
            HStack {
                Spacer()
                Text("LOG SET")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(height: 56)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(exercise == nil)
    }
}