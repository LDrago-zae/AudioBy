import SwiftUI

public struct MangaDetailView: View {
    public let series: MangaSeries
    public let localChapters: [MangaChapter]?
    @State private var chapters: [MangaChapter] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var readingChapter: MangaChapter?
    @Bindable private var library = MangaLibrary.shared

    public init(series: MangaSeries, localChapters: [MangaChapter]?) {
        self.series = series
        self.localChapters = localChapters
    }

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        cover
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(series.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Theme.textDark)
                            Text(series.author)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textMuted)
                            if let saved = library.progress[series.id],
                               let chapter = chapters.first(where: { $0.id == saved.chapterId }) {
                                Button {
                                    readingChapter = chapter
                                } label: {
                                    Text("Continue")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Theme.brandGreen)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if isLoading { ProgressView().padding(.horizontal, 20) }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 20)
                    }

                    if !chapters.isEmpty {
                        sectionLabel("Chapters")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                            ForEach(chapters.prefix(20)) { chapter in
                                Button {
                                    readingChapter = chapter
                                } label: {
                                    Text(chapter.numberLabel)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(library.progress[series.id]?.chapterId == chapter.id ? .black : Theme.textDark)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(library.progress[series.id]?.chapterId == chapter.id ? Theme.brandGreen : Theme.surfaceWhite)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    ForEach(chapters) { chapter in
                        Button {
                            readingChapter = chapter
                        } label: {
                            HStack {
                                Text(chapter.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.textDark)
                                    .lineLimit(2)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Theme.surfaceWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Chapters")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            library.noteOpened(series)
            await load()
        }
        .fullScreenCover(item: $readingChapter) { chapter in
            MangaReaderView(series: series, chapters: chapters, startChapterId: chapter.id)
        }
    }

    @ViewBuilder
    private var cover: some View {
        if let raw = series.coverURL {
            let url = URL(string: raw) ?? URL(fileURLWithPath: raw)
            AsyncImage(url: raw.hasPrefix("http") ? url : URL(fileURLWithPath: raw)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Theme.surfaceSubtle
            }
        } else {
            Theme.surfaceSubtle
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Theme.textDark)
            .padding(.horizontal, 20)
    }

    private func load() async {
        if let localChapters {
            chapters = localChapters
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            chapters = try await MangaDexService.shared.chapters(for: series.id)
            if chapters.isEmpty { errorMessage = "No English chapters are listed for this series." }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
