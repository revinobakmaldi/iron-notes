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
                            ForEach(MuscleGroup.selectableCases, id: \.self) { group in
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
                    Button(action: exportBackup) {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
                    .foregroundColor(.blue)

                    Button(action: {
                        showImporter = true
                    }) {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                    .foregroundColor(.orange)
                } header: {
                    Text("Backup")
                        .foregroundColor(.white)
                } footer: {
                    Text("Importing a backup replaces local workouts, settings, and master exercises.")
                        .foregroundColor(.gray)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("IronNotes")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
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
                exerciseToEdit = (exercise, muscleGroup)
                showEditExercise = true
            }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)

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
