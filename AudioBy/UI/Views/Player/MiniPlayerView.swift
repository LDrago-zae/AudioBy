import SwiftUI

public struct MiniPlayerView: View {
    @Bindable var playerService = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        if let book = playerService.currentBook, playerService.isMiniPlayerVisible {
            HStack(spacing: 12) {
                Button {
                    playerService.togglePlayPause()
                } label: {
                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 36, height: 36)
                        .background(Theme.ink)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(book.author)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.ember)
                    .shadow(color: Theme.ember.opacity(0.35), radius: 12, y: 6)
            )
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
