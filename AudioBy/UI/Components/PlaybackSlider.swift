import SwiftUI

public struct PlaybackSlider: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let onSeek: (TimeInterval) -> Void

    @State private var isDragging: Bool = false
    @State private var dragPosition: TimeInterval = 0
    @State private var verticalOffset: CGFloat = 0

    public init(
        currentTime: TimeInterval,
        duration: TimeInterval,
        onSeek: @escaping (TimeInterval) -> Void
    ) {
        self.currentTime = currentTime
        self.duration = duration
        self.onSeek = onSeek
    }

    private var displayTime: TimeInterval {
        isDragging ? dragPosition : currentTime
    }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(displayTime / duration, 0), 1)
    }

    private var scrubbingRateText: String {
        if verticalOffset > 100 {
            return "Fine Scrubbing (0.1x)"
        } else if verticalOffset > 50 {
            return "Half-Speed Scrubbing (0.5x)"
        } else {
            return "Hi-Speed Scrubbing"
        }
    }

    private var scrubbingRateFactor: Double {
        if verticalOffset > 100 {
            return 0.1
        } else if verticalOffset > 50 {
            return 0.5
        } else {
            return 1.0
        }
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Scrubbing Rate Indicator when dragging
            if isDragging {
                Text(scrubbingRateText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.brandGreen)
                    .transition(.opacity.combined(with: .scale))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color(white: 0.88))
                        .frame(height: isDragging ? 7 : 4)

                    // Filled track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.brandGreen, Theme.brandGreenLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, CGFloat(progress) * geometry.size.width), height: isDragging ? 7 : 4)

                    // Scrubber thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                        .offset(x: max(0, min(CGFloat(progress) * geometry.size.width - (isDragging ? 8 : 6), geometry.size.width - (isDragging ? 16 : 12))))
                }
                .frame(height: 22)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                            verticalOffset = max(0, abs(value.translation.height))
                            let rawRatio = min(max(value.location.x / geometry.size.width, 0), 1)

                            // Apply fine scrubbing modifier
                            if scrubbingRateFactor < 1.0 {
                                let initialPos = currentTime
                                let targetPos = TimeInterval(rawRatio) * max(duration, 1)
                                let finePos = initialPos + (targetPos - initialPos) * scrubbingRateFactor
                                dragPosition = min(max(finePos, 0), duration)
                            } else {
                                dragPosition = TimeInterval(rawRatio) * max(duration, 1)
                            }
                        }
                        .onEnded { value in
                            onSeek(dragPosition)
                            isDragging = false
                            verticalOffset = 0
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                )
            }
            .frame(height: 22)

            // Timestamps
            HStack {
                Text(formatTime(displayTime))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)

                Spacer()

                Text("-" + formatTime(max(0, duration - displayTime)))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(max(0, time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
