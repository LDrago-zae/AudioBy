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
                            .fill(Theme.brandGreen)
                            .frame(width: geo.size.width * CGFloat(progressRatio))
                    }
                }
                .frame(height: 2)

                HStack(spacing: 12) {
                    // Real cover artwork thumbnail
                    CoverArtView(
                        title: book.title,
                        author: book.author,
                        gradientHexes: book.coverGradientColors,
                        coverImageURL: book.coverImageURL,
                        cornerRadius: 8,
                        shadowRadius: 2
                    )
                    .frame(width: 40, height: 40)

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
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(width: 32, height: 32)
                    }

                    // Play / Pause
                    Button {
                        playerService.togglePlayPause()
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 34, height: 34)
                            .background(Theme.brandGreen)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.surfaceWhite)
                        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 1)
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
