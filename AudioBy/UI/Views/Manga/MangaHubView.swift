import SwiftUI

public struct MangaHubView: View {
    @Bindable var library = MangaLibrary.shared
    @Bindable var nav = AppNavigationState.shared
    @State private var items: [MangaSeries] = MangaDexService.curatedCatalog + MangaDexService.webtoonCatalog + MangaDexService.vintageArchiveCatalog
    @State private var selectedSource: MangaSource = .all
    @State private var selectedFormat: String = "All"
    @State private var selectedGenre: String = "All"
    @State private var selectedStatus: String = "All"
    @State private var showingFilterSheet = false
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var catalogPage = 1
    @State private var loadingMore = false
    @State private var canLoadMore = true
    @State private var pendingLoadMore = false

    private let catalogSources: [MangaSource] = [.all, .anilist, .mangadex, .mangahook]
    private let formats = ["All", "Manga", "Manhwa", "Manhua", "Novels"]
    private let tropes = ["All", "Action", "Fantasy", "Mystery", "Slice of Life", "Romance", "Dark Fantasy", "Supernatural"]

    public init() {}

    private var spotlightHero: MangaSeries {
        popularSerializations.first ?? items.first ?? MangaDexService.curatedCatalog[0]
    }

    private var continueReading: [MangaSeries] {
        library.opened.isEmpty ? Array(items.prefix(3)) : library.opened
    }

    private var trendingItems: [MangaSeries] {
        Array(items.dropFirst().prefix(4))
    }

    private var popularSerializations: [MangaSeries] {
        // Source / format / genre are applied in reloadCatalog via the APIs.
        var result = items
        if selectedStatus != "All" {
            result = result.filter { ($0.status?.uppercased() ?? "") == selectedStatus.uppercased() }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return result }
        return result.filter {
            $0.title.lowercased().contains(q) ||
            $0.author.lowercased().contains(q) ||
            ($0.japaneseTitle?.lowercased().contains(q) ?? false) ||
            ($0.genres?.contains { $0.lowercased().contains(q) } ?? false)
        }
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Top Search Pill Bar
                searchPillBar

                // Content Sources Selector Bar
                sourceSelectorPills

                // Format Pills Carousel
                formatPillsRow

                // Editorial Spotlight Hero Banner
                spotlightBanner

                // Continue Reading Section
                continueReadingSection

                // Explore by Tropes
                tropesSection

                // Trending This Week Rail
                trendingRail

                // Editor's Picks Cards
                editorsPicksSection

                // Popular Serializations 2-Column Grid
                popularSerializationsGrid

                // Recently Updated Editorial List
                recentlyUpdatedSection

                Color.clear.frame(height: 60)
            }
            .padding(.vertical, 12)
        }
        .background(MangaTheme.surface)
        .sheet(isPresented: $showingFilterSheet) {
            MangaFilterSheet(
                selectedSource: $selectedSource,
                selectedStatus: $selectedStatus
            )
        }
        .task(id: "\(selectedSource.rawValue)|\(selectedFormat)|\(selectedGenre)") {
            await reloadCatalog(reset: true)
        }
        .onSubmit(of: .text) {
            Task { await remoteSearch() }
        }
    }

    private func reloadCatalog(reset: Bool) async {
        if reset {
            catalogPage = 1
            canLoadMore = true
            isLoading = true
            loadingMore = false
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let genre = selectedGenre == "All" ? nil : selectedGenre
        let page = reset ? 1 : catalogPage
        var remote: [MangaSeries] = []
        if !q.isEmpty {
            remote = await MangaCatalogService.shared.search(q, source: selectedSource)
            canLoadMore = false
        } else {
            remote = await MangaCatalogService.shared.popular(
                source: selectedSource,
                page: page,
                genre: genre,
                format: selectedFormat
            )
        }
        if reset {
            // Clear loading before swapping items so end-of-list onAppear can enqueue page 2.
            isLoading = false
            items = remote
            if remote.count < 10 { canLoadMore = false }
            if pendingLoadMore, canLoadMore {
                pendingLoadMore = false
                await loadMore()
            }
        } else {
            var seen = Set(items.map(\.id))
            let fresh = remote.filter { seen.insert($0.id).inserted }
            items.append(contentsOf: fresh)
            if fresh.isEmpty || fresh.count < 8 { canLoadMore = false }
        }
    }

    private func remoteSearch() async {
        await reloadCatalog(reset: true)
    }

    private func requestLoadMore() {
        Task {
            if isLoading || loadingMore {
                pendingLoadMore = true
                return
            }
            await loadMore()
        }
    }

    private func loadMore() async {
        guard canLoadMore, !loadingMore, !isLoading else {
            if canLoadMore { pendingLoadMore = true }
            return
        }
        loadingMore = true
        catalogPage += 1
        await reloadCatalog(reset: false)
        loadingMore = false
        if pendingLoadMore, canLoadMore {
            pendingLoadMore = false
            await loadMore()
        }
    }

    // MARK: - Search Pill Bar
    private var searchPillBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MangaTheme.secondary)
            TextField("Titles, creators, genres, scanlators...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MangaTheme.ink)
                .submitLabel(.search)
                .onSubmit { Task { await remoteSearch() } }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MangaTheme.secondary)
                }
            }
            Button {
                showingFilterSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle((selectedSource != .all || selectedStatus != "All") ? MangaTheme.vermilion : MangaTheme.ink)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MangaTheme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Source Selector Pills
    private var sourceSelectorPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(catalogSources) { src in
                    let isSel = selectedSource == src
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedSource = src
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: src.icon)
                                .font(.system(size: 11))
                            Text(src.rawValue)
                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                        }
                        .foregroundStyle(isSel ? .white : MangaTheme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Format Pills
    private var formatPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(formats, id: \.self) { fmt in
                    let isSel = selectedFormat == fmt
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedFormat = fmt
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if isSel {
                                Circle()
                                    .fill(MangaTheme.vermilion)
                                    .frame(width: 5, height: 5)
                            }
                            Text(fmt)
                                .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                .foregroundStyle(isSel ? MangaTheme.ink : MangaTheme.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSel ? MangaTheme.surfaceContainer : MangaTheme.surfaceLow)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isSel ? MangaTheme.vermilion.opacity(0.4) : MangaTheme.hairline, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Editorial Spotlight Hero Banner
    private var spotlightBanner: some View {
        NavigationLink(destination: MangaDetailView(series: spotlightHero, localChapters: nil)) {
            ZStack(alignment: .bottomLeading) {
                // Ambient Cover Art
                GeometryReader { geo in
                    if let coverURL = spotlightHero.coverURL, let url = URL(string: coverURL) {
                        CachedAsyncImage(url: url) { phase in
                            if let img = phase.image {
                                img.resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: 260)
                                    .clipped()
                            } else {
                                MangaTheme.readerCard
                            }
                        }
                    } else {
                        MangaTheme.readerCard
                    }
                }
                .frame(height: 260)

                // Dark Editorial Gradient Scrim
                LinearGradient(
                    colors: [
                        Color.clear,
                        MangaTheme.readerCard.opacity(0.4),
                        MangaTheme.readerCard.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Info Overlay
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        MangaBadge("STAFF SPOTLIGHT", isAccent: true)
                        MangaBadge("VOL. 8 DROP")
                        Spacer()
                    }

                    Text("WEEKLY MASTERWORK")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(MangaTheme.vermilionFixed)

                    Text(spotlightHero.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(spotlightHero.synopsis ?? "When the ancient ink-towers collapse, a renegade archivist must decode living scrolls to rekindle ancestral wisdom.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Ch. \(spotlightHero.totalChapters ?? 128)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                            Text("•")
                                .foregroundStyle(Color.white.opacity(0.6))
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(MangaTheme.vermilion)
                            Text(String(format: "%.2f", spotlightHero.rating ?? 4.95))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("Explore Spotlight")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(MangaTheme.vermilion, in: Capsule())
                    }
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MangaTheme.hairline, lineWidth: 1)
            )
            .shadow(color: MangaTheme.cardShadow, radius: 10, y: 4)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Continue Reading Carousel
    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("Continue Reading")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                }
                Spacer()
                Button {
                    nav.mangaTab = .library
                } label: {
                    Text("Shelf (\(continueReading.count))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(continueReading) { series in
                        NavigationLink(destination: MangaDetailView(series: series, localChapters: nil)) {
                            HStack(spacing: 12) {
                                MangaCoverCard(series: series, progress: 0.65, badgeText: "MANGA")
                                    .frame(width: 80, height: 120)

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 10))
                                            .foregroundStyle(MangaTheme.secondary)
                                        Text("2h ago")
                                            .font(.system(size: 11))
                                            .foregroundStyle(MangaTheme.secondary)
                                    }

                                    Text(series.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(MangaTheme.ink)
                                        .lineLimit(2)

                                    Text(series.lastReadChapter ?? "Vol. 14 / Ch. 128")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MangaTheme.secondary)

                                    Spacer()

                                    HStack(spacing: 8) {
                                        Text("84%")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(MangaTheme.vermilion)
                                        Spacer()
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white)
                                            .frame(width: 26, height: 26)
                                            .background(MangaTheme.vermilion, in: Circle())
                                    }
                                }
                                .padding(.vertical, 8)
                                .frame(width: 140)
                            }
                            .padding(8)
                            .background(MangaTheme.surfaceLow)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(MangaTheme.hairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Explore by Tropes
    private var tropesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Explore by Tropes")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Spacer()
                Text("VIEW ALL")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(MangaTheme.vermilion)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tropes, id: \.self) { trope in
                        let isSel = selectedGenre == trope
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedGenre = trope
                            }
                        } label: {
                            Text(trope)
                                .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                .foregroundStyle(isSel ? .white : MangaTheme.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Trending This Week Rail
    private var trendingRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Text("Trending This Week")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Circle()
                        .fill(MangaTheme.vermilion)
                        .frame(width: 6, height: 6)
                }
                Spacer()
                Text("Updated 2h ago")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MangaTheme.secondary)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(trendingItems.enumerated()), id: \.element.id) { index, item in
                        NavigationLink(destination: MangaDetailView(series: item, localChapters: nil)) {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .topLeading) {
                                    MangaCoverCard(series: item, badgeText: item.genres?.first ?? "MANGA")
                                        .frame(width: 125, height: 185)

                                    // Rank Badge
                                    Text("#\(index + 1)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(MangaTheme.vermilion, in: Capsule())
                                        .padding(6)
                                }

                                Text(item.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                                    .lineLimit(1)
                                    .frame(width: 125, alignment: .leading)

                                HStack {
                                    Text(item.totalChapters.map { "Ch. \($0)" } ?? item.status ?? "Manga")
                                        .font(.system(size: 11))
                                        .foregroundStyle(MangaTheme.secondary)
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 9))
                                            .foregroundStyle(MangaTheme.vermilion)
                                        Text(item.rating.map { String(format: "%.2f", $0) } ?? "—")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(MangaTheme.ink)
                                    }
                                }
                                .frame(width: 125)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Editor's Picks
    private var editorsPicksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TOKYO BUREAU SELECTION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(MangaTheme.vermilion)
                Text("Editor's Picks")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(Array(items.prefix(2))) { pick in
                    NavigationLink(destination: MangaDetailView(series: pick, localChapters: nil)) {
                        HStack(spacing: 12) {
                            MangaCoverCard(series: pick)
                                .frame(width: 65, height: 95)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    MangaBadge("Staff Note")
                                    Text("10 min read")
                                        .font(.system(size: 11))
                                        .foregroundStyle(MangaTheme.secondary)
                                }

                                Text(pick.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                                    .lineLimit(1)

                                Text("\"A masterclass in narrative suspense with delicate Japanese brushwork.\"")
                                    .font(.system(size: 12, weight: .regular))
                                    .italic()
                                    .foregroundStyle(MangaTheme.inkVariant)
                                    .lineLimit(2)

                                HStack(spacing: 8) {
                                    Text("📖 \(pick.totalChapters ?? 128) Ch.")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(MangaTheme.secondary)
                                    Text("★ \(String(format: "%.2f", pick.rating ?? 4.95))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(MangaTheme.vermilion)
                                    Text("• \(pick.status ?? "Ongoing")")
                                        .font(.system(size: 11))
                                        .foregroundStyle(MangaTheme.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                library.toggleBookmark(pick)
                            } label: {
                                Image(systemName: library.isBookmarked(pick.id) ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 16))
                                    .foregroundStyle(library.isBookmarked(pick.id) ? MangaTheme.vermilion : MangaTheme.secondary)
                                    .frame(width: 36, height: 36)
                                    .background(MangaTheme.surfaceContainer)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(12)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(MangaTheme.hairline, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Popular Serializations 2-Column Grid
    private var popularSerializationsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("Popular Serializations")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                    Text("\(popularSerializations.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MangaTheme.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MangaTheme.surfaceContainer, in: Capsule())
                }
                Spacer()
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 15))
                    .foregroundStyle(MangaTheme.secondary)
            }
            .padding(.horizontal, 16)

            if popularSerializations.isEmpty {
                Text(isLoading ? "Loading catalog…" : "No titles match these filters. Clear filters or search.")
                    .font(.system(size: 13))
                    .foregroundStyle(MangaTheme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }

            LazyVGrid(
                columns: DuoLayout.adaptiveCardColumns,
                spacing: 16
            ) {
                ForEach(Array(popularSerializations.enumerated()), id: \.element.id) { index, item in
                    NavigationLink(destination: MangaDetailView(series: item, localChapters: nil)) {
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                MangaCoverCard(series: item, badgeText: item.status ?? "ONGOING")
                                    .frame(maxWidth: .infinity)

                                Button {
                                    library.toggleBookmark(item)
                                } label: {
                                    Image(systemName: library.isBookmarked(item.id) ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 12))
                                        .foregroundStyle(library.isBookmarked(item.id) ? MangaTheme.vermilion : .white)
                                        .frame(width: 28, height: 28)
                                        .background(MangaTheme.readerCard.opacity(0.85), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(6)
                            }

                            Text(item.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                                .lineLimit(1)

                            Text(item.genres?.joined(separator: ", ") ?? item.author)
                                .font(.system(size: 11))
                                .foregroundStyle(MangaTheme.secondary)
                                .lineLimit(1)

                            HStack {
                                Text(item.totalChapters.map { "Ch. \($0)" } ?? item.status ?? "Manga")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(MangaTheme.secondary)
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(MangaTheme.vermilion)
                                    Text(item.rating.map { String(format: "%.2f", $0) } ?? "—")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(MangaTheme.ink)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            // Remount when the list grows so staying at the bottom keeps paging MangaDex / AniList.
            Button {
                requestLoadMore()
            } label: {
                HStack(spacing: 8) {
                    if loadingMore { ProgressView().tint(MangaTheme.vermilion) }
                    Text(canLoadMore ? (loadingMore ? "Loading…" : "Load more titles") : "End of results")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(canLoadMore ? MangaTheme.vermilion : MangaTheme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(MangaTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!canLoadMore || loadingMore)
            .id("load-more-\(items.count)-\(catalogPage)")
            .onAppear { requestLoadMore() }
            .padding(.horizontal, 16)

        }
    }

    // MARK: - Recently Updated
    private var recentlyUpdatedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("Recently Updated")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                }
                Spacer()
                Text("All Follows")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MangaTheme.secondary)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(Array(items.prefix(3))) { series in
                    NavigationLink(destination: MangaDetailView(series: series, localChapters: nil)) {
                        HStack(spacing: 12) {
                            MangaCoverCard(series: series)
                                .frame(width: 48, height: 68)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(MangaTheme.vermilion)
                                        .frame(width: 5, height: 5)
                                    Text(series.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(MangaTheme.ink)
                                        .lineLimit(1)
                                }

                                Text("Chapter \(series.totalChapters ?? 128): The Return")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(MangaTheme.inkVariant)

                                Text("15m ago • \(series.publisher ?? "Official Translation")")
                                    .font(.system(size: 11))
                                    .foregroundStyle(MangaTheme.secondary)
                            }

                            Spacer()

                            MangaBadge("NEW", isAccent: true)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MangaTheme.secondary)
                        }
                        .padding(10)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MangaTheme.hairline, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

public struct MangaFilterSheet: View {
    @Binding var selectedSource: MangaSource
    @Binding var selectedStatus: String
    @Environment(\.dismiss) private var dismiss

    private let statusOptions = ["All", "Ongoing", "Completed"]

    public var body: some View {
        NavigationStack {
            ZStack {
                MangaTheme.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Source Selector
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Catalog Sources")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)

                            ForEach(MangaSource.allCases) { source in
                                Button {
                                    selectedSource = source
                                } label: {
                                    HStack {
                                        Image(systemName: source.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(selectedSource == source ? MangaTheme.vermilion : MangaTheme.secondary)
                                            .frame(width: 24)
                                        Text(source.rawValue)
                                            .font(.system(size: 14, weight: selectedSource == source ? .bold : .medium))
                                            .foregroundStyle(MangaTheme.ink)
                                        Spacer()
                                        if selectedSource == source {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(MangaTheme.vermilion)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                Divider().background(MangaTheme.hairline)
                            }
                        }

                        // Status Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Publication Status")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)

                            HStack(spacing: 8) {
                                ForEach(statusOptions, id: \.self) { status in
                                    let isSel = selectedStatus == status
                                    Button {
                                        selectedStatus = status
                                    } label: {
                                        Text(status)
                                            .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                            .foregroundStyle(isSel ? .white : MangaTheme.ink)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceHigh)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Actions
                        HStack(spacing: 12) {
                            Button {
                                selectedSource = .all
                                selectedStatus = "All"
                            } label: {
                                Text("Reset")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(MangaTheme.surfaceHigh)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(MangaTheme.hairline, lineWidth: 1))
                            }

                            Button {
                                dismiss()
                            } label: {
                                Text("Apply Filters")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(MangaTheme.vermilion)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.top, 14)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Filter Manga Lounge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

