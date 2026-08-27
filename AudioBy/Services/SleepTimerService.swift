import Foundation
import Observation

public enum SleepTimerOption: Equatable, Hashable, Sendable {
    case off
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case fortyFiveMinutes
    case sixtyMinutes
    case endOfChapter
    case custom(TimeInterval)

    public var title: String {
        switch self {
        case .off: return "Off"
        case .fiveMinutes: return "5 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .fortyFiveMinutes: return "45 minutes"
        case .sixtyMinutes: return "60 minutes"
        case .endOfChapter: return "End of chapter"
        case .custom(let interval):
            let mins = Int(interval / 60)
            return "\(mins) minutes"
        }
    }

    public var duration: TimeInterval? {
        switch self {
        case .off: return nil
        case .fiveMinutes: return 5 * 60
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .fortyFiveMinutes: return 45 * 60
        case .sixtyMinutes: return 60 * 60
        case .endOfChapter: return nil // dynamic
        case .custom(let interval): return interval
        }
    }
}

@Observable
public final class SleepTimerService: @unchecked Sendable {
    public var selectedOption: SleepTimerOption = .off
    public var remainingTime: TimeInterval = 0
    public var isActive: Bool = false
    public var volumeDuckingFactor: Float = 1.0 // 1.0 to 0.0 during final 30 seconds

    private var timer: Timer?
    private var onTimerComplete: (() -> Void)?
    private var onVolumeDuck: ((Float) -> Void)?

    public init() {}

    public func setTimer(
        option: SleepTimerOption,
        remainingChapterTime: TimeInterval? = nil,
        onVolumeDuck: ((Float) -> Void)? = nil,
        onComplete: @escaping () -> Void
    ) {
        cancel()
        self.selectedOption = option
        self.onTimerComplete = onComplete
        self.onVolumeDuck = onVolumeDuck
        self.volumeDuckingFactor = 1.0

        var targetDuration: TimeInterval = 0

        switch option {
        case .off:
            return
        case .endOfChapter:
            targetDuration = max(remainingChapterTime ?? 0, 1.0)
        default:
            targetDuration = option.duration ?? 0
        }

        guard targetDuration > 0 else { return }

        self.remainingTime = targetDuration
        self.isActive = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.remainingTime > 1.0 {
                    self.remainingTime -= 1.0

                    // Smooth volume ducking during the last 30 seconds
                    if self.remainingTime <= 30.0 {
                        let duckRatio = Float(self.remainingTime / 30.0)
                        self.volumeDuckingFactor = max(0.05, duckRatio)
                        self.onVolumeDuck?(self.volumeDuckingFactor)
                    } else {
                        self.volumeDuckingFactor = 1.0
                    }
                } else {
                    self.remainingTime = 0
                    self.isActive = false
                    self.selectedOption = .off
                    self.volumeDuckingFactor = 1.0
                    self.timer?.invalidate()
                    self.timer = nil
                    self.onVolumeDuck?(1.0)
                    self.onTimerComplete?()
                }
            }
        }
    }

    /// Shake-to-extend: Extends sleep timer by 5 minutes (300 seconds)
    public func extendTimer(by seconds: TimeInterval = 300) {
        guard isActive else { return }
        self.remainingTime += seconds
        self.volumeDuckingFactor = 1.0
        self.onVolumeDuck?(1.0)
    }

    public func cancel() {
        timer?.invalidate()
        timer = nil
        isActive = false
        remainingTime = 0
        selectedOption = .off
        volumeDuckingFactor = 1.0
        onVolumeDuck?(1.0)
    }

    public var formattedRemainingTime: String {
        guard isActive else { return "Off" }
        let total = Int(remainingTime)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
