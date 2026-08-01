import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var selectedMuscleGroup = MuscleGroup.CHEST
    @State private var showAddExercise = false
    @State private var exerciseToEdit: (exercise: MasterExercise, muscleGroup: MuscleGroup)?
    @State private var showEditExercise = false
    @State private var backupDocument = BackupDocument()
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingImportData: Data?
    @State private var showImportConfirmation = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        ZStack {
            Color.ironBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsSection("Timer") {
                    HStack {
                        Text("Rest Timer Duration")
                            .foregroundColor(.ironInk)

                        Spacer()

                        Text("\(settings.restTimerDuration)s")
                            .foregroundColor(.ironMuted)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("30s")
                                .font(.caption)
                                .foregroundColor(.ironMuted)

                            Slider(value: Binding(
                                get: { Double(settings.restTimerDuration) },
                                set: {
                                    settings.restTimerDuration = Int($0)
                                    settings.saveSettings()
                                }
                            ), in: 30...300, step: 10)

                            Text("5m")
                                .font(.caption)
                                .foregroundColor(.ironMuted)
                        }
                    }
                    .padding(.vertical, 8)
                }

                    settingsSection("Units") {
                        unitSelector
                    }

                    settingsSection("Master Exercises") {
                    HStack {
                        Picker("Muscle Group", selection: $selectedMuscleGroup) {
                            ForEach(MuscleGroup.selectableCases, id: \.self) { group in
                                Text(group.rawValue).tag(group)
                            }
                        }
                        .pickerStyle(.menu)

                        Button(action: { showAddExercise = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.ironPrimary)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }

                    masterExercisesList(for: selectedMuscleGroup)
                }

                    settingsSection("Backup") {
                    Button(action: exportBackup) {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
                    .foregroundColor(.ironPrimary)

                    Button(action: {
                        showImporter = true
                    }) {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                    .foregroundColor(.ironAccent)

                    Text("Importing a backup replaces local workouts, settings, and master exercises.")
                        .font(.caption)
                        .foregroundColor(.ironMuted)
                }

                    settingsSection("About") {
                    HStack {
                        Text("Version")
                            .foregroundColor(.ironInk)
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.ironMuted)
                    }

                    HStack {
                        Text("Built with")
                            .foregroundColor(.ironInk)
                        Spacer()
                        Text("SwiftUI + SwiftData")
                            .foregroundColor(.ironMuted)
                    }
                    }
                }
                .padding()
            }
            .background(Color.ironBackground)
        }
        .navigationTitle("Settings")
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
        .sheet(isPresented: $showAddExercise) {
            NewExerciseSheet(muscleGroup: selectedMuscleGroup)
        }
        .sheet(isPresented: $showEditExercise) {
            if let exerciseToEdit = exerciseToEdit {
                EditExerciseSheet(exercise: exerciseToEdit.exercise, muscleGroup: exerciseToEdit.muscleGroup)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: backupDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .confirmationDialog(
            "Replace Local Data?",
            isPresented: $showImportConfirmation,
            titleVisibility: .visible
        ) {
            Button("Import Backup", role: .destructive) {
                importPendingBackup()
            }
            Button("Cancel", role: .cancel) {
                pendingImportData = nil
            }
        } message: {
            Text("This replaces all local workouts, settings, and master exercises with the selected backup.")
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            settings.ensureDefaultMasterExercises()
        }
    }

    private var unitSelector: some View {
        HStack(spacing: 6) {
            ForEach(AppSettings.WeightUnit.allCases, id: \.self) { unit in
                let isSelected = settings.preferredUnit == unit

                Button(action: {
                    settings.preferredUnit = unit
                    settings.saveSettings()
                    HapticManager.light()
                }) {
                    Text(unit.rawValue.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .ironOnPrimary : .ironInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.ironPrimary : Color.ironSurfaceMuted)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.ironSurfaceMuted.opacity(0.65))
        .cornerRadius(12)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

        guard let build else {
            return version
        }

        return "\(version) (\(build))"
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.ironInk)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ironSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ironSurfaceMuted, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func masterExercisesList(for muscleGroup: MuscleGroup) -> some View {
        let exercises = settings.getExercises(for: muscleGroup)

        if exercises.isEmpty {
            Text("No exercises for \(muscleGroup.rawValue)")
                .foregroundColor(.ironMuted)
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
                    .foregroundColor(.ironInk)
                    .fontWeight(.medium)
            }

            Spacer()

            Button(action: {
                exerciseToEdit = (exercise, muscleGroup)
                showEditExercise = true
            }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.ironPrimary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)

            Button(action: {
                settings.removeMasterExercise(exercise, from: muscleGroup)
                HapticManager.light()
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.ironDanger.opacity(0.8))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.ironMuted.opacity(0.15))
        .cornerRadius(8)
    }

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "IronNotes-Backup-\(formatter.string(from: Date()))"
    }

    private func exportBackup() {
        do {
            backupDocument = try BackupManager.makeBackup(sessions: sessions, settings: settings)
            showExporter = true
        } catch {
            showMessage(title: "Export Failed", message: error.localizedDescription)
            HapticManager.error()
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            showMessage(title: "Backup Exported", message: "Your IronNotes backup was saved.")
            HapticManager.success()
        case .failure(let error):
            showMessage(title: "Export Failed", message: error.localizedDescription)
            HapticManager.error()
        }
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                pendingImportData = try Data(contentsOf: url)
                showImportConfirmation = true
            } catch {
                showMessage(title: "Import Failed", message: error.localizedDescription)
                HapticManager.error()
            }

        case .failure(let error):
            showMessage(title: "Import Failed", message: error.localizedDescription)
            HapticManager.error()
        }
    }

    private func importPendingBackup() {
        guard let data = pendingImportData else { return }

        do {
            try BackupManager.importBackup(
                data: data,
                modelContext: modelContext,
                existingSessions: sessions,
                settings: settings
            )
            pendingImportData = nil
            showMessage(title: "Backup Imported", message: "Your IronNotes data was restored.")
            HapticManager.success()
        } catch {
            pendingImportData = nil
            showMessage(title: "Import Failed", message: error.localizedDescription)
            HapticManager.error()
        }
    }

    private func showMessage(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
