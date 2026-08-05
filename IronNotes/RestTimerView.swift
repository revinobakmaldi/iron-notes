import SwiftUI

struct RestTimerView: View {
    @State private var timerManager = TimerManager.shared
    @Environment(\.scenePhase) private var scenePhase

    private var progress: CGFloat {
        guard timerManager.totalTime > 0 else { return 0 }
        return CGFloat(timerManager.remainingTime) / CGFloat(timerManager.totalTime)
    }

    var body: some View {
        ZStack {
            Color.ironBackground.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.ironMuted.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.ironPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.easeInOut(duration: 1), value: timerManager.remainingTime)

                    Text(timerManager.timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.ironInk)
                }
                .frame(width: 200, height: 200)

                Text("Rest Timer")
                    .font(.headline)
                    .foregroundColor(.ironInk)

                HStack(spacing: 20) {
                    Button(action: { timerManager.subtractTime(seconds: 10) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.ironPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)

                    Button(action: { timerManager.toggleTimer() }) {
                        Image(systemName: timerManager.isActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.ironPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)

                    Button(action: { timerManager.addTime(seconds: 10) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.ironPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }

                Button(action: dismiss) {
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(.ironMuted)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
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
    }
}
