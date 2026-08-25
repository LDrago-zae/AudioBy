import SwiftUI

public struct DotMatrixChartView: View {
    public let score: Int
    public let maxScore: Int
    public let onSeeDetails: () -> Void

    // Dot counts for days: S, M, T, W, T, F, S
    private let dayValues: [Int] = [1, 2, 4, 5, 2, 6, 2]
    private let dayLabels: [String] = ["S", "M", "T", "W", "T", "F", "S"]
    private let maxRows: Int = 6

    public init(
        score: Int = 97,
        maxScore: Int = 300,
        onSeeDetails: @escaping () -> Void = {}
    ) {
        self.score = score
        self.maxScore = maxScore
        self.onSeeDetails = onSeeDetails
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Main Matrix Card
            ZStack(alignment: .topTrailing) {
                // Dark background with gradient & ambient dot pattern
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.07, blue: 0.09))
                    .overlay(
                        // Ambient green glow on right side
                        RadialGradient(
                            colors: [
                                Color(red: 0.0, green: 0.85, blue: 0.45).opacity(0.35),
                                Color(red: 0.0, green: 0.55, blue: 0.70).opacity(0.15),
                                Color.clear
                            ],
                            center: .topTrailing,
                            startRadius: 20,
                            endRadius: 220
                        )
                    )
                    .overlay(
                        // Dot grid texture in background
                        BackgroundDotGrid()
                            .opacity(0.35)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 14) {
                    // Header Row
                    HStack {
                        Text("Learn score target")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))

                        Spacer()

                        // "This Week" Dropdown Pill
                        HStack(spacing: 4) {
                            Text("This Week")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    // Score Row
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%03d", score))
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text("/\(maxScore)")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.40))
                    }

                    // Highlight / Subtext
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're improving faster in")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.70))
                        Text("Visual Design")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer(minLength: 8)

                    // 7-Day Dot Matrix Visualizer
                    VStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                VStack(spacing: 4) {
                                    // 6 Vertical Dots per column
                                    ForEach((1...maxRows).reversed(), id: \.self) { row in
                                        let isLit = row <= dayValues[dayIndex]
                                        Circle()
                                            .fill(isLit ? Theme.matrixDotActive : Color.white.opacity(0.10))
                                            .frame(width: 9, height: 9)
                                            .shadow(color: isLit ? Theme.matrixDotActive.opacity(0.8) : .clear, radius: 3)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        // Day Letters
                        HStack(spacing: 0) {
                            ForEach(0..<dayLabels.count, id: \.self) { index in
                                Text(dayLabels[index])
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.75))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .frame(height: 290)
            .shadow(color: Color.black.opacity(0.15), radius: 14, x: 0, y: 8)

            // Card Footer ("See your detail progress" & "See Details" pill)
            HStack {
                Text("See your detail progress")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)

                Spacer()

                Button(action: onSeeDetails) {
                    Text("See Details")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
        }
    }
}

// Subtle matrix dot grid for background
private struct BackgroundDotGrid: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
            let cols = Int(size.width / spacing)
            let rows = Int(size.height / spacing)

            for col in 0..<cols {
                for row in 0..<rows {
                    let point = CGPoint(x: CGFloat(col) * spacing + 8, y: CGFloat(row) * spacing + 8)
                    let rect = CGRect(origin: point, size: CGSize(width: 2, height: 2))
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.18)))
                }
            }
        }
    }
}
