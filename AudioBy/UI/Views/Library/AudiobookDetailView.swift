import SwiftUI

public struct AudiobookDetailView: View {
    public let book: Audiobook
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared

    public init(book: Audiobook) {
        self.book = book
    }

    private var isCurrentlyPlayingThisBook: Bool {
        playerService.currentBook?.id == book.id && playerService.isPlaying
    }

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Cover Art & Header
                    VStack(spacing: 16) {
                        CoverArtView(
                            title: book.title,
                            author: book.author,
                            gradientHexes: book.coverGradientColors,
                            cornerRadius: 20,
                            shadowRadius: 16
                        )
                        .frame(width: 180, height: 180)

                        VStack(spacing: 6) {
                            Text(book.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .multilineTextAlignment(.center)

                            Text("By \(book.author)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            Text("Narrated by \(book.narrator)")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textMuted)
                        }

                        // Rating & Duration Badges
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 13))
                                Text(String(format: "%.1f", book.rating))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                Text("(\(book.reviewCount))")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textMuted)
                            }

                            Circle()
                                .fill(Color(white: 0.80))
                                .frame(width: 4, height: 4)

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .foregroundColor(Theme.brandGreen)
                                    .font(.system(size: 13))
                                Text(book.formattedTotalDuration)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textDark)
                            }
                        }
                    }
                    .padding(.top, 16)

                    // Action Buttons (Play / Favorite)
                    HStack(spacing: 16) {
                        Button {
                            if playerService.currentBook?.id == book.id {
                                playerService.togglePlayPause()
                            } else {
                                playerService.loadAudiobook(book, chapterIndex: book.currentChapterIndex, autoPlay: true)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCurrentlyPlayingThisBook ? "pause.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text(isCurrentlyPlayingThisBook ? "Pause" : (book.progress > 0 ? "Resume" : "Play Session"))
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.activeGreenGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.brandGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                        }

                        Button {
                            repository.toggleFavorite(for: book.id)
                        } label: {
                            Image(systemName: book.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(book.isFavorite ? .red : Theme.textDark)
                                .frame(width: 52, height: 52)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(white: 0.88), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Description / Summary
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About this Session")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.textDark)

                        Text(book.summary)
                            .font(.system(size: 15))
                            .lineSpacing(4)
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Chapters Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Lessons & Chapters (\(book.chapters.count))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.textDark)
                            Spacer()
                        }

                        VStack(spacing: 8) {
                            ForEach(Array(book.chapters.enumerated()), id: \.element.id) { index, chapter in
                                let isThisChapterActive = (playerService.currentBook?.id == book.id && playerService.currentChapterIndex == index)

                                Button {
                                    playerService.loadAudiobook(book, chapterIndex: index, autoPlay: true)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(isThisChapterActive ? Theme.brandGreen : Color(white: 0.92))
                                                .frame(width: 36, height: 36)

                                            if isThisChapterActive && playerService.isPlaying {
                                                Image(systemName: "speaker.wave.2.fill")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white)
                                            } else {
                                                Text("\(chapter.chapterNumber)")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(isThisChapterActive ? .white : Theme.textDark)
                                            }
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(chapter.title)
                                                .font(.system(size: 15, weight: isThisChapterActive ? .bold : .medium))
                                                .foregroundColor(isThisChapterActive ? Theme.brandGreen : Theme.textDark)
                                                .lineLimit(1)

                                            Text(chapter.formattedDuration)
                                                .font(.system(size: 12))
                                                .foregroundColor(Theme.textMuted)
                                        }

                                        Spacer()

                                        Image(systemName: "play.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(isThisChapterActive ? Theme.brandGreen : Theme.textMuted)
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isThisChapterActive ? Theme.brandGreen.opacity(0.1) : Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isThisChapterActive ? Theme.brandGreen.opacity(0.25) : Color(white: 0.90), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
