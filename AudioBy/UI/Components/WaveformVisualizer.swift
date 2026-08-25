import SwiftUI

public struct WaveformVisualizer: View {
    public let isPlaying: Bool
    public var barCount: Int = 28
    public var activeColor: Color = Theme.brandGreen

    @State private var heights: [CGFloat] = []

    public init(isPlaying: Bool, barCount: Int = 28, activeColor: Color = Theme.brandGreen) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self.activeColor = activeColor
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [activeColor, Theme.brandGreenLight],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(
                        isPlaying
                            ? Animation.easeInOut(duration: Double.random(in: 0.35...0.75)).repeatForever(autoreverses: true).delay(Double(index) * 0.03)
                            : .default,
                        value: heights.indices.contains(index) ? heights[index] : 4
                    )
            }
        }
        .frame(height: 36)
        .onAppear {
            generateHeights()
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                generateHeights()
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        if !isPlaying { return 4 }
        guard heights.indices.contains(index) else { return 8 }
        return heights[index]
    }

    private func generateHeights() {
        heights = (0..<barCount).map { _ in
            CGFloat.random(in: 6...34)
        }
    }
}
