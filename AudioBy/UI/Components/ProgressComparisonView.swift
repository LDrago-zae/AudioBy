import SwiftUI

public struct ProgressComparisonView: View {
    public init() {}

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(red: 0.90, green: 0.92, blue: 0.94), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

            HStack(spacing: 12) {
                // Left: Default Wireframe (Cluttered / Unfiltered)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(white: 0.85))
                            .frame(width: 16, height: 16)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.85))
                            .frame(height: 8)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(white: 0.85))
                            .frame(width: 16, height: 16)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.85))
                            .frame(height: 8)
                    }

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.88))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.88))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.92))
                        .frame(height: 28)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                .cornerRadius(14)

                // Center Arrow
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .frame(width: 32, height: 32)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.textDark)
                }

                // Right: Progressive Disclosure Applied (Clean with Green Highlight)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(white: 0.85))
                            .frame(width: 14, height: 14)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.85))
                            .frame(height: 6)
                    }

                    // Focused Green Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: 50, height: 6)
                        }
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.85))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.85))
                            .frame(height: 5)
                    }
                    .padding(10)
                    .background(Theme.activeGreenGradient)
                    .cornerRadius(10)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(white: 0.85))
                            .frame(width: 14, height: 14)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.85))
                            .frame(height: 6)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                .cornerRadius(14)
            }
            .padding(16)
        }
        .frame(height: 190)
    }
}
