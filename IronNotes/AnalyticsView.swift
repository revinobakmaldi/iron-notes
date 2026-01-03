import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(AppSettings.self) private var settings
    
    @State private var selectedExercise: String = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Performance Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    if sessions.isEmpty {
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
                    } else {
                        VStack(spacing: 24) {
                            volumeChart
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            prChart
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
    
    private var volumeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Volume by Muscle Group")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart(volumeData) { data in
                BarMark(
                    x: .value("Volume", data.volume),
                    y: .value("Muscle Group", data.muscleGroup.rawValue)
                )
                .foregroundStyle(Color.blue)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            .padding()
        }
    }
    
    private var prChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("1RM Progression")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Menu {
                    ForEach(uniqueExercises, id: \.self) { exercise in
                        Button(exercise) {
                            selectedExercise = exercise
                        }
                    }
                } label: {
                    Text(selectedExercise.isEmpty ? "Select Exercise" : selectedExercise)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if selectedExercise.isEmpty {
                Text("Select an exercise to view progress")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
            } else {
                Chart(prData) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("1RM", data.est1RM)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", data.date),
                        y: .value("1RM", data.est1RM)
                    )
                    .foregroundStyle(Color.blue)
                    .annotation(position: .top, spacing: 16) {
                        Text("\(Int(data.est1RM)) \(AppSettings.shared.preferredUnit.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, content: .automatic(minimumStride: 5)) { value in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.top, 40)
                .padding(.bottom, 50)
            }
        }
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