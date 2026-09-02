import SwiftUI

public struct SpeedPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let currentSpeed: PlaybackSpeed
    public let onSelectSpeed: (PlaybackSpeed) -> Void

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Playback Speed")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.textDark)
                        .padding(.top, 14)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(PlaybackSpeed.allCases) { speed in
                            Button {
                                onSelectSpeed(speed)
                                dismiss()
                            } label: {
                                VStack(spacing: 4) {
                                    Text(speed.shortTitle)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(currentSpeed == speed ? .black : Theme.textDark)

                                    if speed == .normal {
                                        Text("Normal")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(currentSpeed == speed ? .black.opacity(0.8) : Theme.textMuted)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(currentSpeed == speed ? Theme.brandGreen : Theme.surfaceWhite)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(currentSpeed == speed ? Color.clear : Theme.cardBorder, lineWidth: 1)
                                )
                                .shadow(color: currentSpeed == speed ? Theme.brandGreen.opacity(0.35) : Color.clear, radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
    }
}
