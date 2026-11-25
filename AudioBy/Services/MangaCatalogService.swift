import Foundation

/// Unified manga catalog + reader routing:
/// - Discovery: AniList (rich manga data) + MangaDex + MangaHook
/// - Chapters/pages: always resolve to MangaDex hosted English pages by title when needed
public actor MangaCatalogService {
    public static let shared = MangaCatalogService()

    public func popular(
        source: MangaSource = .all,
        page: Int = 1,
        genre: String? = nil,
        format: String = "All"
    ) async -> [MangaSeries] {
        let offset = max(0, (page - 1) * 50)
        let genreFilter = (genre?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty || $0 == "All" ? nil : $0 }

        func applyLocalFormat(_ list: [MangaSeries]) -> [MangaSeries] {
            guard format != "All" else { return list }
            return list.filter { matchesFormat($0, format) }
        }

        switch source {
        case .anilist:
            let list = (try? await AniListMangaService.shared.popular(page: page, genre: genreFilter, format: format)) ?? []
            return applyLocalFormat(list)
        case .mangahook:
            return applyLocalFormat((try? await MangaHookService.shared.popular(page: page)) ?? [])
        case .mangadex:
            // MangaDex offset pagination — do not pass genre as a title search.
            let list = (try? await MangaDexService.shared.fetchManga(title: nil, offset: offset)) ?? []
            let filtered = genreFilter.map { g in
                list.filter { $0.genres?.contains { $0.caseInsensitiveCompare(g) == .orderedSame } ?? false }
            } ?? list
            return applyLocalFormat(filtered)
        case .komorebi, .archive, .webtoons, .local:
            return page > 1 ? [] : applyLocalFormat((try? await MangaDexService.shared.popular(source: source)) ?? [])
        case .all:
            async let dex = (try? await MangaDexService.shared.fetchManga(title: nil, offset: offset)) ?? []
            async let ani = (try? await AniListMangaService.shared.popular(page: page, genre: genreFilter, format: format)) ?? []
            async let hook = page == 1 ? ((try? await MangaHookService.shared.popular()) ?? []) : []
            var merged: [MangaSeries] = []
            var seenTitles = Set<String>()
            for item in (await dex) + (await ani) + (await hook) {
                let key = item.title.lowercased()
                if seenTitles.insert(key).inserted { merged.append(item) }
            }
            if let g = genreFilter {
                merged = merged.filter { $0.genres?.contains { $0.caseInsensitiveCompare(g) == .orderedSame } ?? false }
            }
            return applyLocalFormat(merged)
        }
    }

    private func matchesFormat(_ series: MangaSeries, _ format: String) -> Bool {
        let genres = (series.genres ?? []).map { $0.lowercased() }
        switch format {
        case "Manhwa":
            return genres.contains { $0.contains("manhwa") } || series.source == .webtoons
        case "Manhua":
            return genres.contains { $0.contains("manhua") }
        case "Novels":
            return genres.contains { $0.contains("novel") }
        case "Manga":
            return !matchesFormat(series, "Manhwa") && !matchesFormat(series, "Manhua") && !matchesFormat(series, "Novels")
        default:
            return true
        }
    }

    public func search(_ query: String, source: MangaSource = .all) async -> [MangaSeries] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        switch source {
        case .anilist:
            return (try? await AniListMangaService.shared.search(q)) ?? []
        case .mangahook:
            return (try? await MangaHookService.shared.search(q)) ?? []
        case .mangadex, .komorebi, .archive, .webtoons, .local:
            return (try? await MangaDexService.shared.search(title: q, source: source)) ?? []
        case .all:
            async let dex = (try? await MangaDexService.shared.search(title: q, source: .mangadex)) ?? []
            async let ani = (try? await AniListMangaService.shared.search(q)) ?? []
            async let hook = (try? await MangaHookService.shared.search(q)) ?? []
            var merged: [MangaSeries] = []
            var seen = Set<String>()
            for item in (await dex) + (await ani) + (await hook) {
                let key = item.title.lowercased()
                if seen.insert(key).inserted { merged.append(item) }
            }
            return merged
        }
    }

    public func chapters(for series: MangaSeries) async -> [MangaChapter] {
        if series.id.hasPrefix("hook-") {
            let hook = (try? await MangaHookService.shared.detail(id: series.id).chapters) ?? []
            if !hook.isEmpty { return hook }
        }

        // Always resolve by title so AniList / curated / shelf ids still get real MangaDex chapters.
        let dex = (try? await MangaDexService.shared.chapters(seriesId: series.id, titleHint: series.title)) ?? []
        if !dex.isEmpty { return dex }

        if let hookId = await MangaHookService.shared.resolveId(forTitle: series.title) {
            return (try? await MangaHookService.shared.detail(id: hookId).chapters) ?? []
        }
        return []
    }

    public func pageURLs(series: MangaSeries, chapter: MangaChapter) async -> [URL] {
        // Offline / imported CBZ pages first — same MangaReaderView path as online chapters.
        let local = CBZImporter.resolvedPageURLs(from: chapter)
        if !local.isEmpty { return local }

        if chapter.id.hasPrefix("hook-") || series.id.hasPrefix("hook-") {
            let hook = (try? await MangaHookService.shared.pages(chapterId: chapter.id)) ?? []
            if !hook.isEmpty { return hook }
        }
        let dex = await MangaDexService.shared.pageURLs(series: series, chapter: chapter)
        if !dex.isEmpty { return dex }

        guard let hookId = await MangaHookService.shared.resolveId(forTitle: series.title),
              let chapters = try? await MangaHookService.shared.detail(id: hookId).chapters else { return [] }
        let match = chapters.first {
            $0.numberLabel == chapter.numberLabel ||
            $0.title.localizedCaseInsensitiveContains(chapter.numberLabel)
        } ?? chapters.first
        guard let match else { return [] }
        return (try? await MangaHookService.shared.pages(chapterId: match.id)) ?? []
    }

    public func enrich(_ series: MangaSeries) async -> MangaSeries {
        guard let hit = await AniListMangaService.shared.enrich(title: series.title) else { return series }
        var s = series
        if s.synopsis == nil || s.synopsis?.isEmpty == true { s.synopsis = hit.synopsis }
        if s.genres == nil || s.genres?.isEmpty == true { s.genres = hit.genres }
        if s.rating == nil { s.rating = hit.rating }
        if s.reviewsCount == nil { s.reviewsCount = hit.reviewsCount }
        if s.totalChapters == nil { s.totalChapters = hit.totalChapters }
        if s.japaneseTitle == nil { s.japaneseTitle = hit.japaneseTitle }
        if s.coverURL == nil { s.coverURL = hit.coverURL }
        if s.releaseYear == nil { s.releaseYear = hit.releaseYear }
        return s
    }
}
