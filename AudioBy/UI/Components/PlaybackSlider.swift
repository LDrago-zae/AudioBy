import SwiftUI

public struct PlaybackSlider: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let onSeek: (TimeInterval) -> Void

    @State private var isDragging: Bool = false
    @State private var dragPosition: TimeInterval = 0

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

    public var body: some View {
        VStack(spacing: 8) {
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
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        .offset(x: max(0, min(CGFloat(progress) * geometry.size.width - (isDragging ? 8 : 6), geometry.size.width - (isDragging ? 16 : 12))))
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let ratio = min(max(value.location.x / geometry.size.width, 0), 1)
                            dragPosition = TimeInterval(ratio) * max(duration, 1)
                        }
                        .onEnded { value in
                            let ratio = min(max(value.location.x / geometry.size.width, 0), 1)
                            let finalTime = TimeInterval(ratio) * max(duration, 1)
                            onSeek(finalTime)
                            isDragging = false
                        }
                )
            }
            .frame(height: 20)

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
