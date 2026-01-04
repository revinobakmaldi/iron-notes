import Foundation
import UserNotifications
import Observation

@Observable
class TimerManager {
    static let shared = TimerManager()

    private(set) var remainingTime: Int = 0
    private(set) var totalTime: Int = 0
    private(set) var isActive: Bool = false

    private var timer: Timer?
    private var startTime: Date?
    private var targetEndTime: Date?
    private var notificationScheduled = false

    private init() {}

    func startTimer(duration: Int) {
        remainingTime = duration
        totalTime = duration
        isActive = true
        startTime = Date()
        targetEndTime = Date().addingTimeInterval(TimeInterval(duration))

        startUITimer()
    }

    func pauseTimer() {
        guard isActive else { return }

        timer?.invalidate()
        timer = nil
        isActive = false
        cancelNotification()

        if let start = startTime, let end = targetEndTime {
            let elapsed = Int(Date().timeIntervalSince(start))
            remainingTime = max(0, remainingTime - elapsed)
            targetEndTime = nil
        }
    }

    func resumeTimer() {
        guard !isActive, remainingTime > 0 else { return }

        isActive = true
        startTime = Date()
        targetEndTime = Date().addingTimeInterval(TimeInterval(remainingTime))

        startUITimer()
    }

    func toggleTimer() {
        if isActive {
            pauseTimer()
        } else {
            resumeTimer()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        remainingTime = 0
        startTime = nil
        targetEndTime = nil
        cancelNotification()
    }

    func addTime(seconds: Int) {
        remainingTime = min(remainingTime + seconds, 600)
        totalTime = max(totalTime, remainingTime)

        if isActive {
            updateTargetEndTime()
        }
    }

    func subtractTime(seconds: Int) {
        remainingTime = max(remainingTime - seconds, 10)
        totalTime = max(totalTime, remainingTime)

        if isActive {
            updateTargetEndTime()
        }
    }

    func appDidEnterBackground() {
        timer?.invalidate()
        timer = nil
        scheduleCompletionNotification()
    }

    func appWillEnterForeground() {
        cancelNotification()
        calculateRemainingTime()

        if isActive {
            startTime = Date()
            updateTargetEndTime()

            if remainingTime > 0 {
                startUITimer()
            } else {
                isActive = false
            }
        }
    }

    private func startUITimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    private func updateTimer() {
        guard isActive, let targetEndTime = targetEndTime else { return }

        let newRemainingTime = max(0, Int(targetEndTime.timeIntervalSinceNow))

        if newRemainingTime != remainingTime {
            remainingTime = newRemainingTime
        }

        if remainingTime == 0 {
            timer?.invalidate()
            timer = nil
            isActive = false
        }
    }

    private func updateTargetEndTime() {
        targetEndTime = Date().addingTimeInterval(TimeInterval(remainingTime))
    }

    private func calculateRemainingTime() {
        if isActive, let targetEndTime = targetEndTime {
            remainingTime = max(0, Int(targetEndTime.timeIntervalSinceNow))
        }
    }

    private func scheduleCompletionNotification() {
        guard isActive, remainingTime > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Complete"
        content.body = "Time to get back to your workout!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "TIMER_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(remainingTime),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "RestTimer",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                self.notificationScheduled = true
            }
        }
    }

    private func cancelNotification() {
        guard notificationScheduled else { return }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        notificationScheduled = false
    }

    var timeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
