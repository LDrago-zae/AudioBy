import SwiftUI
import UIKit

public enum MangaDetailTab: String, CaseIterable, Identifiable {
    case chapters = "Chapters"
    case about = "About / Synopsis"
    case cast = "Characters & Cast"

    public var id: String { rawValue }
}

public struct MangaDetailView: View {
    @Environment(\.dismiss) private var dismiss
    public let series: MangaSeries
    @State private var displaySeries: MangaSeries?
    private var activeSeries: MangaSeries { displaySeries ?? series }
    @State private var ext = ExternalRatings.none
    public let localChapters: [MangaChapter]?

    @State private var chapters: [MangaChapter] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var readingChapter: MangaChapter?
    @State private var externalReader: ExternalChapterRoute?
    @State private var selectedTab: MangaDetailTab = .chapters
    @State private var chapterFilterQuery = ""
    @State private var isDescending = true
    @State private var onlyUnread = false
    @State private var isPlayingAudioDrama = false
    @State private var cast: [AniListMangaService.CharacterCredit] = []
    @State private var castLoading = false

    @Bindable private var library = MangaLibrary.shared
    @Bindable private var playerService = AudioPlayerService.shared

    public init(series: MangaSeries, localChapters: [MangaChapter]?) {
        self.series = series
        self.localChapters = localChapters
    }

    private var filteredChapters: [MangaChapter] {
        var result = chapters
        if onlyUnread {
            result = result.filter { !library.isChapterRead($0.id) }
        }
        let query = chapterFilterQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.numberLabel.localizedCaseInsensitiveContains(query)
            }
        }
        if !isDescending {
            result = result.reversed()
        }
        return result
    }

    private var ctaLabel: String {
        if chapters.isEmpty { return "No chapters available" }
        if let resume = resumeChapter, resume.isExternallyHosted {
            return "Read Ch. \(resume.numberLabel)"
        }
        if library.progress[series.id] != nil {
            return "Continue: Ch. \(resumeChapter?.numberLabel ?? "1")"
        }
        return "Start Reading: Ch. \(resumeChapter?.numberLabel ?? "1")"
    }

    private var resumeChapter: MangaChapter? {
        if let saved = library.progress[series.id],
           let ch = chapters.first(where: { $0.id == saved.chapterId }) {
            return ch
        }
        return chapters.first(where: { !$0.isExternallyHosted }) ?? chapters.first
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            MangaTheme.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Hero Section with Ambient Glow
                    heroSection

                    // Primary Action Deck
                    actionDeck

                    if activeSeries.audioDramaAvailable == true {
                        audioDramaRibbon
                    }

                    // Segmented Tabs
                    tabsBar

                    // Content based on tab
                    switch selectedTab {
                    case .chapters:
                        chaptersSection
                    case .about:
                        aboutSection
                    case .cast:
                        castSection
                    }

                    Spacer(minLength: 90)
                }
                .padding(.bottom, 20)
            }

            // Floating Bottom Resume Pill
            if let resume = resumeChapter {
                floatingResumeBar(for: resume)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .frame(width: 36, height: 36)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                }
            }

            ToolbarItem(placement: .principal) {
                Text(activeSeries.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        library.toggleBookmark(series)
                    } label: {
                        Image(systemName: library.isBookmarked(series.id) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(library.isBookmarked(series.id) ? MangaTheme.vermilion : MangaTheme.ink)
                            .frame(width: 36, height: 36)
                            .background(MangaTheme.surfaceLow)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                    }

                    Button {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first?.rootViewController {
                            let items: [Any] = ["Check out \(activeSeries.title) by \(activeSeries.author) on AudioBy Komorebi!"]
                            let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
                            rootVC.present(av, animated: true)
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MangaTheme.ink)
                            .frame(width: 36, height: 36)
                            .background(MangaTheme.surfaceLow)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                    }
                }
            }
        }
        .fullScreenCover(item: $externalReader) { route in
            AudioByWebReader(url: route.url, title: route.title, subtitle: route.subtitle)
        }
        .fullScreenCover(item: $readingChapter) { chapter in
            MangaReaderView(series: series, chapters: chapters, startChapterId: chapter.id)
        }
        .task {
            ext = await RatingsService.shared.ratings(for: series)
            await loadChapters()
            await NewChapterTracker.shared.refresh(series)
            NewChapterTracker.shared.markSeen(series.id)
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Ambient Top Accent
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MangaTheme.surfaceContainer, MangaTheme.surfaceLow],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Circle()
                        .fill(MangaTheme.vermilion.opacity(0.08))
                        .blur(radius: 40)
                        .offset(x: 80, y: -40)
                )

            HStack(alignment: .top, spacing: 16) {
                // 2:3 Cover Card with Progress Bar
                MangaCoverCard(
                    series: activeSeries,
                    progress: 0.65,
                    badgeText: chapters.isEmpty ? "CATALOG" : "READABLE"
                )
                .frame(width: 130, height: 195)
                .shadow(color: MangaTheme.cardShadow, radius: 10, y: 5)

                // Editorial Metadata Column
                VStack(alignment: .leading, spacing: 6) {
                    // Status & Genre chips
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(MangaTheme.vermilion)
                                .frame(width: 6, height: 6)
                            Text(activeSeries.status ?? "ONGOING")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(MangaTheme.vermilionFixed, in: Capsule())

                        Text(activeSeries.genres?.first ?? "Shounen")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(MangaTheme.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MangaTheme.surfaceContainer, in: Capsule())
                    }

                    Text(activeSeries.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let jp = activeSeries.japaneseTitle {
                        Text(jp)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MangaTheme.secondary)
                            .lineLimit(1)
                    }

                    Text(activeSeries.storyArtist ?? "Story & Art: \(activeSeries.author)")
                        .font(.system(size: 12))
                        .foregroundStyle(MangaTheme.inkVariant)
                        .lineLimit(2)

                    // Rating strip
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(MangaTheme.vermilion)
                        Text(ext.average > 0 ? String(format: "%.2f", ext.average) : "No rating")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                        Text("•")
                            .foregroundStyle(MangaTheme.secondary)
                        Text(ext.count > 0 ? "\(ext.count.formatted(.number.notation(.compactName))) followers" : "MangaDex")
                            .font(.system(size: 11))
                            .foregroundStyle(MangaTheme.secondary)
                    }
                    .padding(.top, 2)

                    // Badges row
                    HStack(spacing: 6) {
                        Text(activeSeries.releaseYear.map { $0.contains("Release") ? $0 : "\($0) Release" } ?? "Year unknown")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(MangaTheme.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(MangaTheme.surfaceContainer, in: RoundedRectangle(cornerRadius: 6))

                        Text(chapters.isEmpty ? (isLoading ? "Loading chapters…" : "0 chapters") : "\(chapters.count) chapters\(chapters.contains(where: { $0.isExternallyHosted }) && !chapters.contains(where: { !$0.isExternallyHosted }) ? " · official reader" : "")")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(MangaTheme.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(MangaTheme.surfaceContainer, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Action Deck
    private var actionDeck: some View {
        HStack(spacing: 10) {
            // Big Primary Vermilion CTA
            Button {
                if let target = resumeChapter {
                    if target.isExternallyHosted, let raw = target.externalURL, let url = URL(string: raw) {
                        externalReader = ExternalChapterRoute(
                            url: url,
                            title: activeSeries.title,
                            subtitle: "Ch. \(target.numberLabel) · \(target.scanGroup ?? "Official")"
                        )
                    } else {
                        readingChapter = target
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(ctaLabel)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [MangaTheme.vermilion, MangaTheme.vermilionDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: MangaTheme.buttonRadius, style: .continuous))
                .shadow(color: MangaTheme.vermilion.opacity(0.3), radius: 8, y: 3)
            }
            .disabled(resumeChapter == nil)

            // Bookmark Button
            Button {
                library.toggleBookmark(series)
            } label: {
                Image(systemName: library.isBookmarked(series.id) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(library.isBookmarked(series.id) ? MangaTheme.vermilion : MangaTheme.ink)
                    .frame(width: 48, height: 48)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: MangaTheme.buttonRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: MangaTheme.buttonRadius).stroke(MangaTheme.hairline, lineWidth: 1))
            }

            // Batch Download Button
            Button {
                for ch in chapters.prefix(5) {
                    library.downloadChapter(ch, series: series)
                }
            } label: {
                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
                    .frame(width: 48, height: 48)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: MangaTheme.buttonRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: MangaTheme.buttonRadius).stroke(MangaTheme.hairline, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Official Audio Drama & OST Ribbon
    private var audioDramaRibbon: some View {
        Button {
            isPlayingAudioDrama.toggle()
            if let book = AudiobookRepository.shared.audiobooks.first {
                playerService.playAudiobook(book, chapterIndex: 0)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MangaTheme.vermilion)
                        .frame(width: 40, height: 40)
                    Image(systemName: isPlayingAudioDrama ? "waveform" : "headphones")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Official Audio Drama & OST Available")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Text("Japanese Voice Cast • 14 Tracks Available")
                        .font(.system(size: 11))
                        .foregroundStyle(MangaTheme.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MangaTheme.secondary)
            }
            .padding(10)
            .background(MangaTheme.surfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(MangaTheme.hairline, lineWidth: 1))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation Tabs
    private var tabsBar: some View {
        HStack(spacing: 8) {
            ForEach(MangaDetailTab.allCases) { tab in
                let isSel = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: isSel ? .bold : .medium))
                            .foregroundStyle(isSel ? .white : MangaTheme.ink)
                        if tab == .chapters {
                            Text("• \(chapters.count)")
                                .font(.system(size: 12, weight: isSel ? .bold : .regular))
                                .foregroundStyle(isSel ? .white.opacity(0.8) : MangaTheme.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isSel ? MangaTheme.readerCard : MangaTheme.surfaceLow)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1)
                    )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Chapters Section
    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search & Filter controls
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(MangaTheme.secondary)
                    TextField("Filter by chapter or title...", text: $chapterFilterQuery)
                        .font(.system(size: 13))
                        .foregroundStyle(MangaTheme.ink)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(MangaTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MangaTheme.hairline, lineWidth: 1))

                Button {
                    withAnimation { isDescending.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 11))
                        Text(isDescending ? "Desc" : "Asc")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(MangaTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(MangaTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { onlyUnread.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(onlyUnread ? MangaTheme.vermilion : MangaTheme.secondary)
                            .frame(width: 5, height: 5)
                        Text("Unread")
                            .font(.system(size: 11, weight: onlyUnread ? .bold : .medium))
                    }
                    .foregroundStyle(onlyUnread ? MangaTheme.vermilion : MangaTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(MangaTheme.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(MangaTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            if isLoading {
                HStack(spacing: 8) {
                    ProgressView().tint(MangaTheme.vermilion)
                    Text("Loading chapters from MangaDex...")
                        .font(.system(size: 13))
                        .foregroundStyle(MangaTheme.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if chapters.isEmpty {
                Text("No chapters listed for this title. Official releases like Jujutsu Kaisen are often MangaPlus-only on MangaDex.")
                    .font(.system(size: 13))
                    .foregroundStyle(MangaTheme.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
            } else if filteredChapters.isEmpty {
                Text("No chapters match this filter. Clear Unread/search or switch Asc/Desc.")
                    .font(.system(size: 13))
                    .foregroundStyle(MangaTheme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            // Chapter list rows
            LazyVStack(spacing: 8) {
                ForEach(filteredChapters) { chapter in
                    let isRead = library.isChapterRead(chapter.id)
                    Button {
                        if chapter.isExternallyHosted, let raw = chapter.externalURL, let url = URL(string: raw) {
                            externalReader = ExternalChapterRoute(
                                url: url,
                                title: activeSeries.title,
                                subtitle: "Ch. \(chapter.numberLabel) · \(chapter.scanGroup ?? "Official")"
                            )
                        } else {
                            readingChapter = chapter
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Chapter number pill
                            Text(chapter.numberLabel)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isRead ? MangaTheme.secondary : MangaTheme.ink)
                                .frame(width: 44, height: 44)
                                .background(MangaTheme.surfaceContainer)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(chapter.title)
                                        .font(.system(size: 14, weight: isRead ? .medium : .bold))
                                        .foregroundStyle(isRead ? MangaTheme.secondary : MangaTheme.ink)
                                        .lineLimit(1)

                                    if chapter.scanGroup == "NEW" {
                                        MangaBadge("NEW", isAccent: true)
                                    }
                                }

                                Text("\(chapter.releaseDate ?? "Recent") • \(chapter.pageCount ?? 24) pages • \(chapter.scanGroup ?? "Weekly Shounen")")
                                    .font(.system(size: 11))
                                    .foregroundStyle(MangaTheme.secondary)
                            }

                            Spacer()

                            if isRead {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(MangaTheme.secondary)
                            } else if chapter.isDownloaded == true || library.isChapterDownloaded(chapter.id) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(MangaTheme.vermilion)
                            } else {
                                Button {
                                    library.downloadChapter(chapter, series: series)
                                } label: {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 16))
                                        .foregroundStyle(MangaTheme.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MangaTheme.hairline, lineWidth: 1))
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Synopsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MangaTheme.ink)

            Text(activeSeries.synopsis?.isEmpty == false ? activeSeries.synopsis! : "No synopsis available for this title yet.")
                .font(.system(size: 14))
                .lineSpacing(4)
                .foregroundStyle(MangaTheme.inkVariant)

            Divider().background(MangaTheme.hairline)

            Text("Information")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MangaTheme.ink)

            VStack(spacing: 8) {
                infoRow(label: "Source", value: activeSeries.publisher ?? activeSeries.source.rawValue)
                infoRow(label: "Release Year", value: activeSeries.releaseYear ?? "—")
                infoRow(label: "Status", value: activeSeries.status ?? "—")
                infoRow(label: "Author", value: activeSeries.author)
                if let genres = activeSeries.genres, !genres.isEmpty {
                    infoRow(label: "Genres", value: genres.prefix(4).joined(separator: ", "))
                }
            }
        }
        .padding(16)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(MangaTheme.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MangaTheme.ink)
        }
    }

    // MARK: - Characters & Cast
    private var castSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Characters")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MangaTheme.ink)

            if castLoading {
                ProgressView().tint(MangaTheme.vermilion).frame(maxWidth: .infinity).padding(.vertical, 20)
            } else if cast.isEmpty {
                Text("No character data found for this title on AniList.")
                    .font(.system(size: 13))
                    .foregroundStyle(MangaTheme.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(cast) { c in
                        castRow(name: c.name, role: c.role, cv: c.voiceActor ?? "—", imageURL: c.imageURL)
                    }
                }
            }
        }
        .padding(16)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func castRow(name: String, role: String, cv: String, imageURL: String? = nil) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(MangaTheme.surfaceContainer).frame(width: 40, height: 40)
                if let imageURL, let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Text(String(name.prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                        }
                    }
                    .frame(width: 40, height: 40).clipShape(Circle())
                } else {
                    Text(String(name.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Text(role)
                    .font(.system(size: 12))
                    .foregroundStyle(MangaTheme.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("CV")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MangaTheme.secondary)
                Text(cv)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MangaTheme.vermilion)
            }
        }
    }

    // MARK: - Floating Bottom Resume Bar
    private func floatingResumeBar(for chapter: MangaChapter) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MangaTheme.vermilion)
                    .frame(width: 38, height: 38)
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("RESUME READING")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Color.white.opacity(0.7))
                Text(chapter.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                readingChapter = chapter
            } label: {
                HStack(spacing: 4) {
                    Text("Open")
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(MangaTheme.vermilion, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            MangaTheme.readerCard.opacity(0.95)
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 16, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func loadChapters() async {
        library.noteOpened(series)
        if let local = localChapters, !local.isEmpty {
            chapters = local
            for chapter in local where !chapter.imagePaths.isEmpty {
                library.markChapterDownloaded(chapter.id)
            }
            return
        }
        isLoading = true
        defer { isLoading = false }
        chapters = await MangaCatalogService.shared.chapters(for: series)
        displaySeries = await MangaCatalogService.shared.enrich(series)
        castLoading = true
        cast = await AniListMangaService.shared.characters(forTitle: series.title)
        castLoading = false
    }
}
