import SwiftUI

public struct BookmarksView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var repository = AudiobookRepository.shared

    public init() {}

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            if playerService.bookmarks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.textLightMuted)

                    Text("No Bookmarks Yet")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(Theme.textDark)

                    Text("While listening to audio briefs or lessons, tap the bookmark icon to save quotes and timestamps.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(playerService.bookmarks) { bookmark in
                            let book = repository.audiobooks.first { $0.id == bookmark.audiobookId }

                            Button {
                                if let book = book {
                                    let chIndex = book.chapters.firstIndex(where: { $0.id == bookmark.chapterId }) ?? 0
                                    playerService.loadAudiobook(book, chapterIndex: chIndex, autoPlay: true)
                                    playerService.seek(to: bookmark.timestamp)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(Theme.brandGreen)
                                            .font(.system(size: 13))

                                        Text(book?.title ?? "Audio Session")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(Theme.textDark)
                                            .lineLimit(1)

                                        Spacer()

                                        Text(bookmark.formattedTimestamp)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.brandGreen)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Theme.brandGreen.opacity(0.12))
                                            .cornerRadius(6)
                                    }

                                    Text(bookmark.chapterTitle)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.textMuted)

                                    if !bookmark.note.isEmpty {
                                        Text("\"\(bookmark.note)\"")
                                            .font(.system(size: 14))
                                            .italic()
                                            .foregroundColor(Theme.textDark)
                                            .padding(.top, 2)
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationTitle("Saved Bookmarks")
    }
}
