import SwiftUI

struct RestTimerView: View {
    @State private var timerManager = TimerManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var duration: Int
    var onDismiss: () -> Void

    init(duration: Int = 90, onDismiss: @escaping () -> Void) {
        self.duration = duration
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
                        .trim(from: 0, to: CGFloat(timerManager.remainingTime) / CGFloat(timerManager.totalTime))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.easeInOut(duration: 1), value: timerManager.remainingTime)

                    Text(timerManager.timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 200, height: 200)

                Text("Rest Timer")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 20) {
                    Button(action: { timerManager.subtractTime(seconds: 10) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .frame(minWidth: 44, minHeight: 44)

                    Button(action: { timerManager.toggleTimer() }) {
                        Image(systemName: timerManager.isActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .frame(minWidth: 44, minHeight: 44)

                    Button(action: { timerManager.addTime(seconds: 10) }) {
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
            timerManager.startTimer(duration: duration)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                timerManager.appDidEnterBackground()
            case .active:
                timerManager.appWillEnterForeground()
            default:
                break
            }
        }
        .onChange(of: timerManager.remainingTime) { oldValue, newValue in
            if newValue == 0 && !timerManager.isActive {
                HapticManager.success()
                dismiss()
            }
        }
    }

    private func dismiss() {
        timerManager.stopTimer()
        onDismiss()
    }
}
