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

    private var timer: Timer?
    private var onTimerComplete: (() -> Void)?

    public init() {}

    public func setTimer(
        option: SleepTimerOption,
        remainingChapterTime: TimeInterval? = nil,
        onComplete: @escaping () -> Void
    ) {
        cancel()
        self.selectedOption = option
        self.onTimerComplete = onComplete

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
                } else {
                    self.remainingTime = 0
                    self.isActive = false
                    self.selectedOption = .off
                    self.timer?.invalidate()
                    self.timer = nil
                    self.onTimerComplete?()
                }
            }
        }
    }

    public func cancel() {
        timer?.invalidate()
        timer = nil
        isActive = false
        remainingTime = 0
        selectedOption = .off
    }

    public var formattedRemainingTime: String {
        guard isActive else { return "Off" }
        let total = Int(remainingTime)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
