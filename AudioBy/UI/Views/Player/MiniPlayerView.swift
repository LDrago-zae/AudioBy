import SwiftUI

/// Japanese editorial Mini Player Bar for active audiobook/novel playback.
/// Matches the Komorebi aesthetic with washi background and vermilion accents.
public struct MiniPlayerView: View {
    @Bindable var playerService = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        if let book = playerService.currentBook, playerService.isMiniPlayerVisible {
            HStack(spacing: 12) {
                // Play / Pause Circle
                Button {
                    playerService.togglePlayPause()
                } label: {
                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(MangaTheme.vermilion)
                        .clipShape(Circle())
                        .shadow(color: MangaTheme.vermilion.opacity(0.35), radius: 6, y: 2)
                }
                .buttonStyle(.plain)

                // 2:3 Miniature Cover
                CoverArtView(
                    title: book.title,
                    author: book.author,
                    gradientHexes: book.coverGradientColors,
                    coverImageURL: book.coverImageURL,
                    cornerRadius: 6,
                    ratio: 2/3
                )
                .frame(width: 28, height: 42)

                // Book Title & Author / Chapter
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(book.author)
                            .font(.system(size: 11))
                            .foregroundStyle(MangaTheme.secondary)
                            .lineLimit(1)

                        if book.progress > 0 {
                            Text("• \(Int(book.progress * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                        }
                    }
                }

                Spacer(minLength: 8)

                // Sonic Waveform Visualizer
                HStack(spacing: 2) {
                    ForEach(0..<4) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(playerService.isPlaying ? MangaTheme.vermilion : MangaTheme.secondary.opacity(0.35))
                            .frame(width: 2.5, height: playerService.isPlaying ? CGFloat([14, 22, 10, 18][i]) : 6)
                            .animation(.easeInOut(duration: 0.35).repeatForever().delay(Double(i) * 0.08), value: playerService.isPlaying)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(MangaTheme.surfaceLow.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MangaTheme.hairline, lineWidth: 1)
            )
            .shadow(color: MangaTheme.cardShadow, radius: 10, y: 4)
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
