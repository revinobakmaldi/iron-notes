import SwiftUI

struct RestTimerView: View {
    @State private var remainingTime: Int
    @State private var totalTime: Int
    @State private var timer: Timer?
    @State private var isActive: Bool = false
    var onDismiss: () -> Void
    
    init(duration: Int = 90, onDismiss: @escaping () -> Void) {
        self._remainingTime = State(initialValue: duration)
        self._totalTime = State(initialValue: duration)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(remainingTime) / CGFloat(totalTime))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.easeInOut(duration: 1), value: remainingTime)
                    
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 200, height: 200)
                
                Text("Rest Timer")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    Button(action: decreaseTime) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    
                    Button(action: toggleTimer) {
                        Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    
                    Button(action: increaseTime) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                
                Button(action: dismiss) {
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .onAppear {
            startTimer()
        }
    }
    
    private var timeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        isActive = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timer?.invalidate()
                isActive = false
                HapticManager.success()
                dismiss()
            }
        }
    }
    
    private func toggleTimer() {
        if isActive {
            timer?.invalidate()
            isActive = false
        } else {
            if remainingTime > 0 {
                startTimer()
            }
        }
    }
    
    private func increaseTime() {
        remainingTime = min(remainingTime + 10, 600)
        totalTime = max(totalTime, remainingTime)
    }
    
    private func decreaseTime() {
        remainingTime = max(remainingTime - 10, 10)
        totalTime = max(totalTime, remainingTime)
    }
    
    private func dismiss() {
        timer?.invalidate()
        onDismiss()
    }
}