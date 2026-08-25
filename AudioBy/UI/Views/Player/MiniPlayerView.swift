import SwiftUI

public struct MiniPlayerView: View {
    @Bindable var playerService = AudioPlayerService.shared

    public init() {}

    private var progressRatio: Double {
        guard playerService.duration > 0 else { return 0 }
        return min(max(playerService.currentTime / playerService.duration, 0), 1)
    }

    public var body: some View {
        if let book = playerService.currentBook, playerService.isMiniPlayerVisible {
            VStack(spacing: 0) {
                // Mini progress line
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                        Rectangle()
                            .fill(Theme.activeGreenGradient)
                            .frame(width: geo.size.width * CGFloat(progressRatio))
                    }
                }
                .frame(height: 2)

                HStack(spacing: 12) {
                    // Small glowing dot thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.12, green: 0.15, blue: 0.18))
                        Image(systemName: "headphones")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.brandGreen)
                    }
                    .frame(width: 38, height: 38)

                    // Titles
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playerService.currentChapter?.title ?? book.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("Narrated by \(book.narrator)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.65))
                            .lineLimit(1)
                    }

                    Spacer()

                    // Quick Jump 15s
                    Button {
                        playerService.jump(by: -15)
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                    }

                    // Play / Pause
                    Button {
                        playerService.togglePlayPause()
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Theme.brandGreen)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                playerService.isFullScreenPlayerPresented = true
            }
            .sheet(isPresented: $playerService.isFullScreenPlayerPresented) {
                FullScreenPlayerView()
            }
        }
    }
}
