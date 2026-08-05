import SwiftUI

struct SmartParserInput: View {
    let exercise: ExerciseLog?
    var previousSets: [SetEntry] = []
    var showsHeader: Bool = true
    var isEmbedded: Bool = false
    var onLog: (Double, Int, Int, Bool) -> Void
    var onToggleTimer: () -> Void = {}
    @Environment(AppSettings.self) private var settings

    @State private var weight: Double = 0
    @State private var reps: Int = 0
    @State private var isSingleArm: Bool = false
    @State private var showTextMode: Bool = false
    @State private var inputText = ""

    var lastSet: SetEntry? {
        exercise?.uniqueSets.sorted(by: { $0.timestamp > $1.timestamp }).first
    }

    var previousSessionLastSet: SetEntry? {
        previousSets.uniquedByID().sorted(by: { $0.timestamp > $1.timestamp }).first
    }

    var suggestedSet: SetEntry? {
        lastSet ?? previousSessionLastSet
    }

    private var suggestionTitle: String {
        lastSet == nil && previousSessionLastSet != nil ? "Previous session:" : "Last set:"
    }

    private var unitLabel: String {
        settings.preferredUnit.rawValue
    }

    private var horizontalPadding: CGFloat {
        isEmbedded ? 0 : 16
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsHeader {
                HStack {
                    Text(exercise?.exerciseName ?? "Select Exercise")
                        .font(.headline)
                        .foregroundColor(.ironPrimary)

                    Spacer()

                    modeToggleButton
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 12)
            } else {
                HStack {
                    Text(showTextMode ? "Text Logger" : "Quick Logger")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.ironMuted)

                    Spacer()

                    modeToggleButton
                }
                .padding(.bottom, 8)
            }

            if showTextMode {
                textModeInput
            } else {
                quickModeInput
            }
        }
        .background(isEmbedded ? Color.clear : Color.ironBackground)
        .onAppear {
            applySuggestedSetIfNeeded()
        }
        .onChange(of: exercise?.id) { _, _ in
            applySuggestedSet()
        }
        .onChange(of: previousSessionLastSet?.id) { _, _ in
            applySuggestedSetIfNeeded()
        }
    }

    private var modeToggleButton: some View {
        Button(action: {
            HapticManager.light()
            showTextMode.toggle()
        }) {
            Image(systemName: showTextMode ? "number" : "textformat")
                .foregroundColor(.ironMuted)
        }
        .frame(minWidth: 44, minHeight: 44)
    }

    private var textModeInput: some View {
        VStack(spacing: 12) {
            Text("Quick text mode: e.g., 100\(unitLabel) 10r")
                .font(.caption)
                .foregroundColor(.ironMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, horizontalPadding)

            if lastSet != nil || previousSessionLastSet != nil {
                suggestionChips
                    .padding(.horizontal, horizontalPadding)
            }

            HStack(spacing: 12) {
                TextField("100\(unitLabel) 10r", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .foregroundColor(.ironInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.ironMuted.opacity(0.15))
                    .cornerRadius(8)

                Button(action: {
                    if let parsed = WorkoutParser.parse(inputText) {
                        onLog(parsed.weight, parsed.reps, parsed.setCount, parsed.isSingleArm)
                        inputText = ""
                        showTextMode = false
                        HapticManager.success()
                    } else {
                        HapticManager.error()
                    }
                }) {
                    Text("Log")
                        .font(.headline)
                        .foregroundColor(.ironOnPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.ironPrimary)
                        .cornerRadius(8)
                }

                Button(action: {
                    showTextMode = false
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.ironMuted)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 12)
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let lastSet {
                    suggestionChip(title: "Last set", set: lastSet)
                }

                if let previousSessionLastSet {
                    suggestionChip(title: "Previous", set: previousSessionLastSet)
                }
            }
        }
    }

    private func suggestionChip(title: String, set: SetEntry) -> some View {
        Button(action: {
            applySetToInputs(set)
            inputText = parserText(for: set)
            HapticManager.light()
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.ironMuted)

                Text(lastSetSummary(set))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.ironInk)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.ironMuted.opacity(0.15))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var quickModeInput: some View {
        VStack(spacing: 8) {
            if let suggestedSet {
                HStack {
                    Text(suggestionTitle)
                        .font(.caption)
                        .foregroundColor(.ironMuted)

                    Spacer()

                    Text(lastSetSummary(suggestedSet))
                        .font(.caption)
                        .foregroundColor(.ironMuted)

                    Button(action: {
                        applySuggestedSet()
                        HapticManager.light()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.ironPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, horizontalPadding)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                weightInput
                repsInput
            }
            .padding(.horizontal, horizontalPadding)

            HStack {
                setNumberDisplay
                Spacer()
                isSingleArmToggle
            }
            .padding(.horizontal, horizontalPadding)

            logButton
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 8)
        }
    }

    private var weightInput: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Weight")
                .font(.caption)
                .foregroundColor(.ironMuted)

            HStack(spacing: 6) {
                Button(action: {
                    HapticManager.light()
                    weight = max(weight - 2.5, 0)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.ironPrimary)
                }
                .frame(minWidth: 32, minHeight: 36)

                TextField("0.0", value: $weight, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.ironInk)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 52)

                Button(action: {
                    HapticManager.light()
                    weight += 2.5
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.ironPrimary)
                }
                .frame(minWidth: 32, minHeight: 36)

                Text(unitLabel)
                    .font(.caption)
                    .foregroundColor(.ironMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.ironMuted.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var repsInput: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Reps")
                .font(.caption)
                .foregroundColor(.ironMuted)

            HStack(spacing: 6) {
                Button(action: {
                    HapticManager.light()
                    reps = max(reps - 1, 1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.ironPrimary)
                }
                .frame(minWidth: 32, minHeight: 36)

                TextField("0", value: $reps, format: .number)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.ironInk)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 52)

                Button(action: {
                    HapticManager.light()
                    reps += 1
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.ironPrimary)
                }
                .frame(minWidth: 32, minHeight: 36)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.ironMuted.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var setNumberDisplay: some View {
        let completedSets = exercise?.uniqueSets.reduce(0) { $0 + $1.setCount } ?? 0
        let nextSetNumber = completedSets + 1
        return HStack(spacing: 12) {
            Text("Set #\(nextSetNumber)")
                .font(.subheadline)
                .foregroundColor(.ironMuted)
        }
    }

    private var isSingleArmToggle: some View {
        Button(action: {
            HapticManager.light()
            isSingleArm.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: isSingleArm ? "hand.point.left.fill" : "hand.point.left")
                    .foregroundColor(isSingleArm ? .blue : .gray)

                Text("Single Arm")
                    .font(.caption)
                    .foregroundColor(isSingleArm ? .blue : .gray)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(isSingleArm ? Color.ironPrimary.opacity(0.1) : Color.ironMuted.opacity(0.1))
            .cornerRadius(6)
        }
        .frame(minWidth: 44, minHeight: 44)
    }

    private var logButton: some View {
        Button(action: {
            HapticManager.success()
            onLog(weight, reps, 1, isSingleArm)
        }) {
            HStack {
                Spacer()
                Text("LOG SET")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.ironOnPrimary)
                Spacer()
            }
            .frame(height: 40)
            .background(Color.ironPrimary)
            .cornerRadius(8)
        }
        .disabled(exercise == nil || reps <= 0)
    }

    private func lastSetSummary(_ set: SetEntry) -> String {
        let setPrefix = set.setCount > 1 ? "\(set.setCount) sets of " : ""
        let singleArmSuffix = set.isSingleArm ? " · single arm" : ""
        return "\(setPrefix)\(formatWeight(set.weight))\(unitLabel) x \(set.reps)\(singleArmSuffix)"
    }

    private func applySuggestedSetIfNeeded() {
        guard weight == 0, reps == 0 else {
            return
        }
        applySuggestedSet()
    }

    private func applySuggestedSet() {
        guard let suggestedSet else {
            weight = 0
            reps = 0
            isSingleArm = false
            return
        }

        applySetToInputs(suggestedSet)
    }

    private func applySetToInputs(_ set: SetEntry) {
        weight = set.weight
        reps = set.reps
        isSingleArm = set.isSingleArm
    }

    private func parserText(for set: SetEntry) -> String {
        let singleArmPrefix = set.isSingleArm ? "SA " : ""
        return "\(singleArmPrefix)\(formatWeight(set.weight))x\(set.reps)"
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}
