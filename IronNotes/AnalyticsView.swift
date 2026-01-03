import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [WorkoutSession]
    @Environment(AppSettings.self) private var settings

    @State private var selectedExercise: String = ""
    @State private var showTooltip: Bool = false
    @State private var tooltipPosition: CGPoint = .zero
    @State private var selectedPRPoint: PRDataPoint?

    var sortedSessions: [WorkoutSession] {
        sessions.sorted { $0.date > $1.date }
    }

    let muscleGroupColors: [MuscleGroup: Color] = [
        .CHEST: Color(red: 0.95, green: 0.45, blue: 0.35),
        .BACK: Color(red: 0.35, green: 0.55, blue: 0.9),
        .LEGS: Color(red: 0.35, green: 0.8, blue: 0.45),
        .SHOULDERS: Color(red: 0.95, green: 0.65, blue: 0.25),
        .ARMS: Color(red: 0.75, green: 0.4, blue: 0.8),
        .CORE: Color(red: 0.35, green: 0.7, blue: 0.85),
        .FULL_BODY: Color(red: 0.5, green: 0.5, blue: 0.95)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Performance Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if sessions.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 24) {
                            dashboardOverview
                            volumeChartSection
                            prChartSection
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Complete workouts to see your progress")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var dashboardOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dashboard")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "calendar",
                    value: "\(totalWorkouts)",
                    label: "Total Workouts",
                    color: .blue
                )

                StatCard(
                    icon: "scalemass",
                    value: formatVolume(totalVolume),
                    label: "Total Volume",
                    color: .purple
                )

                StatCard(
                    icon: "star.fill",
                    value: "\(totalPRs)",
                    label: "PRs Achieved",
                    color: .yellow
                )

                StatCard(
                    icon: "clock",
                    value: formatDuration(averageDuration),
                    label: "Avg Duration",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
    }

    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Volume by Muscle Group")
                .font(.headline)
                .foregroundColor(.white)

            if volumeData.isEmpty {
                Text("No volume data")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 60)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(16)
            } else {
                Chart(volumeData) { data in
                    BarMark(
                        x: .value("Volume", data.volume),
                        y: .value("Muscle Group", data.muscleGroup.rawValue)
                    )
                    .foregroundStyle(muscleGroupColors[data.muscleGroup] ?? .blue)
                    .cornerRadius(8)
                }
                .frame(height: 280)
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
    }

    private var prChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("1RM Progression")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        selectedExercise = ""
                        selectedPRPoint = nil
                    } label: {
                        Text("All")
                            .font(.subheadline)
                            .foregroundColor(selectedExercise.isEmpty ? .white : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedExercise.isEmpty ? Color.blue : Color.gray.opacity(0.2))
                            .cornerRadius(20)
                    }

                    ForEach(uniqueExercises, id: \.self) { exercise in
                        let max1RM = exerciseMax1RM(exercise)
                        Button {
                            selectedExercise = exercise
                            selectedPRPoint = nil
                        } label: {
                            VStack(spacing: 2) {
                                Text(exercise)
                                    .font(.subheadline)
                                    .foregroundColor(selectedExercise == exercise ? .white : .gray)
                                if max1RM > 0 {
                                    Text("\(Int(max1RM)) \(AppSettings.shared.preferredUnit.rawValue)")
                                        .font(.caption2)
                                        .foregroundColor(selectedExercise == exercise ? .white.opacity(0.8) : .gray.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedExercise == exercise ? Color.blue : Color.gray.opacity(0.2))
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if selectedExercise.isEmpty {
                Text("Select an exercise to view progress")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 60)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(16)
            } else {
                ZStack {
                    Chart(prData) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("1RM", data.est1RM)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("1RM", data.est1RM)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(6)
                    }
                    .frame(height: 320)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisValueLabel(format: .dateTime.month().day())
                                .foregroundStyle(.gray)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                .foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(.gray)
                        }
                    }
                    .chartBackground { _ in
                        GeometryReader { geo in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.15), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                    .chartPlotStyle { plotArea in
                        plotArea
                    }
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    if let pr = selectedPRPoint {
                        VStack(spacing: 4) {
                            Text(pr.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack(spacing: 4) {
                                Text("\(Int(pr.est1RM))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(AppSettings.shared.preferredUnit.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.9))
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .position(tooltipPosition)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if let dataPoint = findNearestDataPoint(to: value.location) {
                                selectedPRPoint = dataPoint
                                showTooltip = true
                                tooltipPosition = value.location
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                showTooltip = false
                            }
                        }
                )

                if let bestPR = bestPR {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Best: \(Int(bestPR.est1RM)) \(AppSettings.shared.preferredUnit.rawValue)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
    }

    private func findNearestDataPoint(to location: CGPoint) -> PRDataPoint? {
        guard !prData.isEmpty else { return nil }
        let sortedData = prData.sorted { $0.date < $1.date }
        return sortedData.min { a, b in
            abs(a.date.timeIntervalSince1970 - Double(location.x)) <
            abs(b.date.timeIntervalSince1970 - Double(location.x))
        }
    }

    private var totalWorkouts: Int {
        sessions.filter { $0.isCompleted }.count
    }

    private var totalVolume: Double {
        sessions.reduce(0.0) { sum, session in
            sum + session.exercises.reduce(0.0) { exerciseSum, exercise in
                exerciseSum + exercise.sets.reduce(0.0) { setSum, set in
                    setSum + (set.weight * Double(set.reps))
                }
            }
        }
    }

    private var totalPRs: Int {
        sessions.reduce(0) { sum, session in
            sum + session.exercises.reduce(0) { exerciseSum, exercise in
                exerciseSum + exercise.sets.filter { $0.isPR }.count
            }
        }
    }

    private var averageDuration: Int {
        let completedSessions = sessions.filter { $0.isCompleted }
        guard !completedSessions.isEmpty else { return 0 }
        return completedSessions.reduce(0, +) / completedSessions.count
    }

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: NSNumber(value: volume)) ?? "0") kg"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func exerciseMax1RM(_ exercise: String) -> Double {
        let exerciseSets: [SetEntry] = []
        for session in sessions {
            for ex in session.exercises {
                if ex.exerciseName == exercise {
                    exerciseSets.append(contentsOf: ex.sets)
                }
            }
        }
        return exerciseSets.map { $0.estimated1RM }.max() ?? 0.0
    }

    private var bestPR: PRDataPoint? {
        prData.max { $0.est1RM < $1.est1RM }
    }

    private var uniqueExercises: [String] {
        Set(sessions.flatMap { $0.exercises.map { $0.exerciseName } }).sorted()
    }

    private var volumeData: [VolumeDataPoint] {
        var muscleVolumes: [MuscleGroup: Double] = [:]

        for session in sessions {
            for exercise in session.exercises {
                let exerciseVolume = exercise.sets.reduce(0.0) { sum, set in
                    sum + (set.weight * Double(set.reps))
                }

                muscleVolumes[exercise.muscleGroup, default: 0] += exerciseVolume
            }
        }

        return muscleVolumes.map { muscle, volume in
            VolumeDataPoint(muscleGroup: muscle, volume: Int(volume))
        }.sorted { $0.volume > $1.volume }
    }

    private var prData: [PRDataPoint] {
        guard !selectedExercise.isEmpty else { return [] }

        var exerciseSets: [(date: Date, est1RM: Double)] = []

        for session in sessions {
            for exercise in session.exercises {
                if exercise.exerciseName == selectedExercise {
                    for set in exercise.sets {
                        exerciseSets.append((date: set.timestamp, est1RM: set.estimated1RM))
                    }
                }
            }
        }

        return exerciseSets.sorted { $0.date < $1.date }.map { data in
            PRDataPoint(date: data.date, est1RM: data.est1RM)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 24))
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [color.opacity(0.2), color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let muscleGroup: MuscleGroup
    let volume: Int
}

struct PRDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let est1RM: Double
}
