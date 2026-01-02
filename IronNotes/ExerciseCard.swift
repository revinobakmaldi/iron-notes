import SwiftUI

struct ExerciseCard: View {
    let exercise: ExerciseLog
    var previousSets: [SetEntry] = []
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(exercise.muscleGroup.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.3))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            if exercise.sets.isEmpty {
                Text("No sets logged yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
                setsTable
            }
            
            if !previousSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Session")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    previousSessionTable
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var setsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Set")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .center)
                    .foregroundColor(.gray)
                
                Text("Weight")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .center)
                    .foregroundColor(.gray)
                
                Text("Reps")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .center)
                    .foregroundColor(.gray)
                
                Text("")
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            
            ForEach(exercise.sets.sorted(by: { $0.timestamp < $1.timestamp })) { set in
                HStack {
                    Text("\(set.setCount)")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .center)
                        .foregroundColor(.white)
                    
                    Text("\(Int(set.weight))kg")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .center)
                        .foregroundColor(.white)
                    
                    Text("\(set.reps)")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .center)
                        .foregroundColor(.white)
                    
                    if set.isPR {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                            .frame(width: 44, alignment: .trailing)
                    } else {
                        Text("")
                            .frame(width: 44)
                    }
                }
                .padding(.vertical, 8)
                .background(set.isPR ? Color.yellow.opacity(0.1) : Color.clear)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var previousSessionTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Set")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .center)
                    .foregroundColor(.gray)
                
                Text("Weight")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .center)
                    .foregroundColor(.gray)
                
                Text("Reps")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .center)
                    .foregroundColor(.gray)
                
                Text("")
                    .frame(width: 44)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            ForEach(previousSets.prefix(5).sorted(by: { $0.timestamp < $1.timestamp })) { set in
                HStack {
                    Text("\(set.setCount)")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .center)
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("\(Int(set.weight))kg")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .center)
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("\(set.reps)")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .center)
                        .foregroundColor(.gray.opacity(0.6))
                    
                    if set.isPR {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.4))
                            .frame(width: 44, alignment: .trailing)
                    } else {
                        Text("")
                            .frame(width: 44)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .cornerRadius(12)
        .opacity(0.6)
    }
}