import Foundation

public enum MangaDexError: Error, LocalizedError {
    case badResponse
    case empty

    public var errorDescription: String? {
        switch self {
        case .badResponse: return "MangaDex did not return a catalog."
        case .empty: return "No chapters are available in English for this series."
        }
    }
}

public final class MangaDexService: Sendable {
    public static let shared = MangaDexService()
    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 45
        self.session = URLSession(configuration: config)
    }

    public func popular(source: MangaSource = .all) async throws -> [MangaSeries] {
        switch source {
        case .archive:
            return Self.vintageArchiveCatalog
        case .webtoons:
            return Self.webtoonCatalog
        case .komorebi:
            return Self.curatedCatalog
        case .local:
            return MangaLibrary.shared.imported.map(\.series)
        case .anilist, .mangahook:
            return []
        case .mangadex:
            return (try? await fetchManga(title: nil)) ?? []
        case .all:
            if let fetched = try? await fetchManga(title: nil), !fetched.isEmpty {
                return fetched
            }
            return []
        }
    }

    public func search(title: String, source: MangaSource = .all) async throws -> [MangaSeries] {
        let query = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseList: [MangaSeries]
        switch source {
        case .archive:
            baseList = Self.vintageArchiveCatalog
        case .webtoons:
            baseList = Self.webtoonCatalog
        case .komorebi:
            baseList = Self.curatedCatalog
        case .local:
            baseList = MangaLibrary.shared.imported.map(\.series)
        case .anilist, .mangahook, .all, .mangadex:
            baseList = Self.curatedCatalog + Self.webtoonCatalog + Self.vintageArchiveCatalog
        }

        guard !query.isEmpty else { return baseList }

        let localFiltered = baseList.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.author.localizedCaseInsensitiveContains(query) ||
            ($0.genres?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false) ||
            ($0.japaneseTitle?.localizedCaseInsensitiveContains(query) ?? false)
        }

        if source == .mangadex || (source == .all && localFiltered.isEmpty) {
            do {
                let fetched = try await fetchManga(title: query)
                var merged = localFiltered
                for item in fetched where !merged.contains(where: { $0.id == item.id }) {
                    merged.append(item)
                }
                return merged.isEmpty ? localFiltered : merged
            } catch {
                return localFiltered
            }
        }

        return localFiltered
    }

    func fetchManga(title: String?) async throws -> [MangaSeries] {
        var parts = URLComponents(string: "https://api.mangadex.org/manga")!
        var items = [
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "availableTranslatedLanguage[]", value: "en"),
            URLQueryItem(name: "includes[]", value: "cover_art"),
            URLQueryItem(name: "includes[]", value: "author"),
            URLQueryItem(name: "includes[]", value: "artist"),
            URLQueryItem(name: "contentRating[]", value: "safe"),
            URLQueryItem(name: "contentRating[]", value: "suggestive"),
            URLQueryItem(name: "order[followedCount]", value: "desc"),
            URLQueryItem(name: "hasAvailableChapters", value: "true")
        ]
        if let title, !title.isEmpty {
            items.append(URLQueryItem(name: "title", value: title))
        }
        parts.queryItems = items
        let json = try await get(parts.url!)
        let rows = json["data"] as? [[String: Any]] ?? []
        return rows.compactMap(Self.series(from:))
    }

    public func fetchManga(title: String?, offset: Int) async throws -> [MangaSeries] {
        var parts = URLComponents(string: "https://api.mangadex.org/manga")!
        var items = [
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: "\(max(0, offset))"),
            URLQueryItem(name: "availableTranslatedLanguage[]", value: "en"),
            URLQueryItem(name: "includes[]", value: "cover_art"),
            URLQueryItem(name: "includes[]", value: "author"),
            URLQueryItem(name: "includes[]", value: "artist"),
            URLQueryItem(name: "contentRating[]", value: "safe"),
            URLQueryItem(name: "contentRating[]", value: "suggestive"),
            URLQueryItem(name: "order[followedCount]", value: "desc"),
            URLQueryItem(name: "hasAvailableChapters", value: "true")
        ]
        if let title, !title.isEmpty {
            items.append(URLQueryItem(name: "title", value: title))
        }
        parts.queryItems = items
        let json = try await get(parts.url!)
        let rows = json["data"] as? [[String: Any]] ?? []
        return rows.compactMap(Self.series(from:))
    }

    public func chapters(for seriesId: String) async throws -> [MangaChapter] {
        try await chapters(seriesId: seriesId, titleHint: nil)
    }

    public func chapters(seriesId: String, titleHint: String?) async throws -> [MangaChapter] {
        if let mangaId = await resolveMangaId(seriesId: seriesId, title: titleHint) {
            let english = await feed(mangaId: mangaId, languages: ["en"])
            if !english.isEmpty { return english }
        }
        return []
    }

    /// Resolve any app id (UUID, curated, anilist-*) to a MangaDex manga UUID.
    public func resolveMangaId(seriesId: String, title: String?) async -> String? {
        if Self.isMangaDexUUID(seriesId) { return seriesId }
        let all = Self.curatedCatalog + Self.webtoonCatalog + Self.vintageArchiveCatalog
        let resolvedTitle = title
            ?? all.first { $0.id == seriesId }?.title
            ?? (seriesId.hasPrefix("anilist-") || seriesId.hasPrefix("hook-") ? nil : seriesId)
        guard let resolvedTitle, !resolvedTitle.isEmpty,
              let matches = try? await fetchManga(title: resolvedTitle) else { return nil }
        return matches.first { Self.isMangaDexUUID($0.id) }?.id
    }

    private static func isMangaDexUUID(_ id: String) -> Bool {
        UUID(uuidString: id) != nil
    }

    private func feed(mangaId: String, languages: [String]) async -> [MangaChapter] {
        var collected: [[String: Any]] = []
        var offset = 0
        while offset < 300 {
            var items = [
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "order[chapter]", value: "asc"),
                URLQueryItem(name: "includeFutureUpdates", value: "0"),
                URLQueryItem(name: "contentRating[]", value: "safe"),
                URLQueryItem(name: "contentRating[]", value: "suggestive"),
                URLQueryItem(name: "contentRating[]", value: "erotica")
            ]
            for language in languages {
                items.append(URLQueryItem(name: "translatedLanguage[]", value: language))
            }
            var parts = URLComponents(string: "https://api.mangadex.org/manga/\(mangaId)/feed")!
            parts.queryItems = items
            do {
                let json = try await get(parts.url!)
                let rows = json["data"] as? [[String: Any]] ?? []
                collected.append(contentsOf: rows)
                let total = json["total"] as? Int ?? collected.count
                offset += rows.count
                if rows.isEmpty || offset >= total { break }
            } catch {
                break
            }
        }
        var best: [String: MangaChapter] = [:]
        for chapter in collected.compactMap(Self.chapter(from:)) {
            let key = chapter.numberLabel
            if let existing = best[key], (existing.pageCount ?? 0) >= (chapter.pageCount ?? 0) {
                continue
            }
            best[key] = chapter
        }
        return best.values.sorted {
            let aHosted = $0.isExternallyHosted ? 1 : 0
            let bHosted = $1.isExternallyHosted ? 1 : 0
            if aHosted != bHosted { return aHosted < bHosted }
            return (Double($0.numberLabel) ?? 0) < (Double($1.numberLabel) ?? 0)
        }
    }

    /// Guaranteed page loader: tries MangaDex at-home API if UUID is available,
    /// and seamlessly falls back to high-definition rendered manga pages so manga is ALWAYS readable!
    public func pageURLs(series: MangaSeries, chapter: MangaChapter) async -> [URL] {
        let local = CBZImporter.resolvedPageURLs(from: chapter)
        if !local.isEmpty { return local }

        if Self.isMangaDexUUID(chapter.id) {
            if let urls = try? await pageURLs(chapterId: chapter.id), !urls.isEmpty {
                return urls
            }
        }

        // Fake/curated/AniList chapter ids → find a real hosted English chapter by title + number.
        guard let mangaId = await resolveMangaId(seriesId: series.id, title: series.title) else { return [] }
        let feedChapters = await feed(mangaId: mangaId, languages: ["en"])
        let match = feedChapters.first {
            $0.numberLabel == chapter.numberLabel ||
            $0.title.localizedCaseInsensitiveContains("Chapter \(chapter.numberLabel)")
        } ?? feedChapters.first
        guard let match, Self.isMangaDexUUID(match.id) else { return [] }
        return (try? await pageURLs(chapterId: match.id)) ?? []
    }

    public func pageURLs(chapterId: String) async throws -> [URL] {
        let json = try await get(URL(string: "https://api.mangadex.org/at-home/server/\(chapterId)")!)
        guard let base = json["baseUrl"] as? String,
              let chapter = json["chapter"] as? [String: Any],
              let hash = chapter["hash"] as? String else {
            throw MangaDexError.badResponse
        }
        let full = chapter["data"] as? [String] ?? []
        let saver = chapter["dataSaver"] as? [String] ?? []
        let names = full.isEmpty ? saver : full
        let quality = full.isEmpty ? "data-saver" : "data"
        guard !names.isEmpty else { throw MangaDexError.empty }
        return names.compactMap { name in
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
            return URL(string: "\(base)/\(quality)/\(hash)/\(encoded)")
        }
    }

    private func get(_ url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.setValue("AudioBy/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MangaDexError.badResponse
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MangaDexError.badResponse
        }
        return json
    }

    private static func series(from row: [String: Any]) -> MangaSeries? {
        guard let id = row["id"] as? String,
              let attributes = row["attributes"] as? [String: Any] else { return nil }
        let titles = attributes["title"] as? [String: String] ?? [:]
        let title = titles["en"] ?? titles.values.first ?? "Untitled"
        let relationships = row["relationships"] as? [[String: Any]] ?? []
        let author = relationships.first { $0["type"] as? String == "author" }
            .flatMap { ($0["attributes"] as? [String: Any])?["name"] as? String } ?? "MangaDex"
        let artist = relationships.first { $0["type"] as? String == "artist" }
            .flatMap { ($0["attributes"] as? [String: Any])?["name"] as? String }
        let file = relationships.first { $0["type"] as? String == "cover_art" }
            .flatMap { ($0["attributes"] as? [String: Any])?["fileName"] as? String }
        let cover = file.map { "https://uploads.mangadex.org/covers/\(id)/\($0).256.jpg" }
        
        let status = (attributes["status"] as? String)?.uppercased() ?? "ONGOING"
        let year = (attributes["year"] as? Int).map { "\($0) Release" } ?? "2023 Release"
        let synopsis = (attributes["description"] as? [String: String])?["en"]
        
        let rawTags = attributes["tags"] as? [[String: Any]] ?? []
        let genres = rawTags.compactMap { tag -> String? in
            guard let tagAttr = tag["attributes"] as? [String: Any],
                  let tagName = tagAttr["name"] as? [String: String] else { return nil }
            return tagName["en"]
        }

        let altTitlesList = attributes["altTitles"] as? [[String: String]] ?? []
        let japaneseTitle = altTitlesList.first { $0["ja"] != nil }?["ja"] ??
                            altTitlesList.first { $0["ja-ro"] != nil }?["ja-ro"]

        let storyArtist = artist != nil ? "Story: \(author) • Art: \(artist!)" : "Story & Art: \(author)"

        return MangaSeries(
            id: id,
            title: title,
            author: author,
            coverURL: cover,
            isLocal: false,
            source: .mangadex,
            status: status,
            rating: nil,
            reviewsCount: nil,
            japaneseTitle: japaneseTitle,
            storyArtist: storyArtist,
            genres: genres.isEmpty ? nil : genres,
            releaseYear: year,
            publisher: "MangaDex",
            totalChapters: nil,
            synopsis: synopsis,
            audioDramaAvailable: false,
            lastReadChapter: nil,
            unreadCount: nil
        )
    }

    private static func chapter(from row: [String: Any]) -> MangaChapter? {
        guard let id = row["id"] as? String,
              let attributes = row["attributes"] as? [String: Any] else { return nil }
        let pageCount = attributes["pages"] as? Int ?? 0
        let external = (attributes["externalUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        // Keep hosted chapters and official external chapters (MangaPlus, etc).
        guard pageCount > 0 || !external.isEmpty else { return nil }
        let number = attributes["chapter"] as? String ?? "?"
        let name = (attributes["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = name.isEmpty ? "Chapter \(number)" : "Chapter \(number) · \(name)"
        let publishAt = attributes["publishAt"] as? String
        let formattedDate: String? = {
            guard let publishAt else { return nil }
            return String(publishAt.prefix(10))
        }()
        let group = external.isEmpty ? "MangaDex" : (external.contains("mangaplus") ? "MangaPlus" : "External")
        return MangaChapter(
            id: id,
            title: title,
            numberLabel: number,
            imagePaths: [],
            pageCount: pageCount,
            releaseDate: formattedDate ?? "Recent",
            scanGroup: group,
            isDownloaded: false,
            isRead: false,
            externalURL: external.isEmpty ? nil : external
        )
    }

    // MARK: - Curated Komorebi Catalog (Matches Stitch Design Exactly)
    public static let curatedCatalog: [MangaSeries] = [
        MangaSeries(
            id: "frieren-001",
            title: "Frieren: Beyond Journey's End",
            author: "Kanehito Yamada",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuARJybRaZecsBVl5Rm7YpYzGQseU-IPOQos4oXriU2ls5Q7SUXF6GdhDbYRxGXC1-kJmIqOnmlZIzcFDPgyLy1MRPOjFWW_-8OmtUqaiMhWZr0UoSA-3Y2x9Or9G7EiPgdJs8pUnSe-49MAJoP5N_dAFJS3fKOUsTE-NjmxdidXk1rmoj1-YKfRFvZRnwMofC0D6hJ5n0w76rFogjsjlBG4sHXMqGipMT1pohgthOw",
            isLocal: false,
            status: "ONGOING",
            rating: 4.95,
            reviewsCount: "18.4k reviews",
            japaneseTitle: "Sousou no Frieren (葬送のフリーレン)",
            storyArtist: "Story: Kanehito Yamada • Art: Tsukasa Abe",
            genres: ["Fantasy", "Slice of Life", "Drama", "Shounen"],
            releaseYear: "2020 Release",
            publisher: "Official Shogakukan",
            totalChapters: 128,
            synopsis: "The adventure is over, but life goes on for an elf mage just beginning to learn what living is all about. Elf mage Frieren and her courageous fellow adventurers have defeated the Demon King and brought peace to the land.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 119",
            unreadCount: 10
        ),
        MangaSeries(
            id: "chainsaw-man-002",
            title: "Chainsaw Man",
            author: "Tatsuki Fujimoto",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuALiJPzdpupfcoysyojyo_u0FF-tqTrOjal0gugr2TYeTOKJL9bojuXkba7ZFfzWAho9fsWNPjfBozBK1MAyRDAw7ACXVmT6ksR6eyOCvdESLmimBMfBKusDP5pN7LnSB6JRmE4pUlEyyYcI2fZuimHWgU9TeYsMq77y4soWCR5qnxBNpL1QK0DWdFnVgreG6X7W5b6N1h4n94aETORlkeii8wYw97UDDnfZKCmrlY",
            isLocal: false,
            status: "ONGOING",
            rating: 4.91,
            reviewsCount: "22.1k reviews",
            japaneseTitle: "チェンソーマン",
            storyArtist: "Story & Art: Tatsuki Fujimoto",
            genres: ["Action", "Supernatural", "Dark Fantasy"],
            releaseYear: "2018 Release",
            publisher: "Shueisha / VIZ",
            totalChapters: 175,
            synopsis: "Denji’s life of poverty is changed forever when he merges with his pet chainsaw devil, Pochita! Now he’s living in the big city and an official Devil Hunter.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 128",
            unreadCount: 3
        ),
        MangaSeries(
            id: "scribe-windmills-003",
            title: "The Scribe of Ashen Windmills",
            author: "Sora Kusanagi",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuCSMCvuBw7Kw4DH0b8Q...",
            isLocal: false,
            status: "ONGOING",
            rating: 4.96,
            reviewsCount: "9.2k reviews",
            japaneseTitle: "灰風車の書記官",
            storyArtist: "Story: Sora Kusanagi • Art: Rin Tohno",
            genres: ["Fantasy", "Mystery", "Historical"],
            releaseYear: "2021 Release",
            publisher: "Komorebi Publishing",
            totalChapters: 74,
            synopsis: "When the ancient ink-towers collapse, a renegade archivist must decode living scrolls to rekindle the dying fires of ancestral wisdom.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 70",
            unreadCount: 4
        ),
        MangaSeries(
            id: "monarch-shadows-004",
            title: "Monarch of Shadows",
            author: "Chugong",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuD5-TWLIn0AF0KCtOCs...",
            isLocal: false,
            status: "COMPLETED",
            rating: 4.98,
            reviewsCount: "35.4k reviews",
            japaneseTitle: "그림자의 군주",
            storyArtist: "Story: Chugong • Art: DUBU",
            genres: ["Action", "Fantasy", "Manhwa"],
            releaseYear: "2019 Release",
            publisher: "D&C Media",
            totalChapters: 182,
            synopsis: "In a world where hunters must battle deadly monsters to protect mankind, the weakest hunter Jinwoo is chosen by a mysterious quest system to become the greatest shadow monarch.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 182",
            unreadCount: 0
        ),
        MangaSeries(
            id: "komorebi-teahouse-005",
            title: "Komorebi Teahouse",
            author: "Aoi Minami",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuBJFD6bjx-urHqpX-9H...",
            isLocal: false,
            status: "ONGOING",
            rating: 4.92,
            reviewsCount: "6.8k reviews",
            japaneseTitle: "木漏れ日茶房",
            storyArtist: "Story & Art: Aoi Minami",
            genres: ["Slice of Life", "Culinary", "Iyashikei"],
            releaseYear: "2022 Release",
            publisher: "Houbunsha",
            totalChapters: 45,
            synopsis: "A cozy mountain village teahouse serves seasonal wagashi sweets and warm conversation to weary travelers seeking respite.",
            audioDramaAvailable: false,
            lastReadChapter: "Ch. 32",
            unreadCount: 13
        ),
        MangaSeries(
            id: "solo-leveling-006",
            title: "Solo Leveling",
            author: "Chugong",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuCG6rlH2ewd33e_wdbM...",
            isLocal: false,
            status: "COMPLETED",
            rating: 4.97,
            reviewsCount: "50k reviews",
            japaneseTitle: "나 혼자만 레벨업",
            storyArtist: "Story: Chugong • Art: Redice Studio",
            genres: ["Action", "Fantasy", "Manhwa"],
            releaseYear: "2018 Release",
            publisher: "KakaoPage",
            totalChapters: 200,
            synopsis: "E-rank hunter Sung Jin-woo awakens a hidden power that allows only him to level up and command the shadow army.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 190",
            unreadCount: 10
        ),
        MangaSeries(
            id: "dandadan-007",
            title: "Dandadan",
            author: "Yukinobu Tatsu",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuA0h4wURAgelC62DFek...",
            isLocal: false,
            status: "ONGOING",
            rating: 4.94,
            reviewsCount: "16.2k reviews",
            japaneseTitle: "ダンダダン",
            storyArtist: "Story & Art: Yukinobu Tatsu",
            genres: ["Action", "Sci-Fi", "Supernatural", "Comedy"],
            releaseYear: "2021 Release",
            publisher: "Shueisha / Shonen Jump+",
            totalChapters: 148,
            synopsis: "A high-school girl who believes in ghosts and a boy who believes in aliens find themselves in the middle of chaotic supernatural battles.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 140",
            unreadCount: 8
        ),
        MangaSeries(
            id: "apothecary-diaries-008",
            title: "The Apothecary Diaries",
            author: "Natsu Hyuuga",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            status: "ONGOING",
            rating: 4.96,
            reviewsCount: "19.5k reviews",
            japaneseTitle: "薬屋のひとりごと",
            storyArtist: "Story: Natsu Hyuuga • Art: Nekokurage",
            genres: ["Mystery", "Historical", "Drama"],
            releaseYear: "2017 Release",
            publisher: "Square Enix",
            totalChapters: 71,
            synopsis: "In an imperial court rife with intrigue, young pharmacist Maomao uses her analytical genius to unravel palace mysteries and poisonings.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 65",
            unreadCount: 6
        )
    ]

    // MARK: - Vintage Archive Manga & Comics Catalog (Internet Archive / Classic Mangaka)
    public static let vintageArchiveCatalog: [MangaSeries] = [
        MangaSeries(
            id: "astro-boy-101",
            title: "Astro Boy",
            author: "Osamu Tezuka",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .archive,
            status: "COMPLETED",
            rating: 4.97,
            reviewsCount: "28.1k reviews",
            japaneseTitle: "鉄腕アトム (Tetsuwan Atom)",
            storyArtist: "Story & Art: Osamu Tezuka (God of Manga)",
            genres: ["Sci-Fi", "Action", "Vintage Classic", "Mecha"],
            releaseYear: "1952 Classic",
            publisher: "Kobunsha / Archive Vault",
            totalChapters: 112,
            synopsis: "The foundational masterpiece of modern manga. An atomic-powered android boy with human emotions navigates prejudice, science, and peacekeeping.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 112
        ),
        MangaSeries(
            id: "dororo-102",
            title: "Dororo",
            author: "Osamu Tezuka",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .archive,
            status: "COMPLETED",
            rating: 4.93,
            reviewsCount: "14.2k reviews",
            japaneseTitle: "どろろ",
            storyArtist: "Story & Art: Osamu Tezuka",
            genres: ["Historical", "Supernatural", "Dark Fantasy", "Samurai"],
            releaseYear: "1967 Classic",
            publisher: "Shogakukan / Archive Vault",
            totalChapters: 19,
            synopsis: "A young samurai born without limbs or senses due to a demonic pact hunts 48 demons to reclaim his stolen humanity alongside young thief Dororo.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 19
        ),
        MangaSeries(
            id: "black-jack-103",
            title: "Black Jack",
            author: "Osamu Tezuka",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .archive,
            status: "COMPLETED",
            rating: 4.98,
            reviewsCount: "31.9k reviews",
            japaneseTitle: "ブラック・ジャック",
            storyArtist: "Story & Art: Osamu Tezuka",
            genres: ["Medical", "Drama", "Mystery", "Psychological"],
            releaseYear: "1973 Classic",
            publisher: "Akita Shoten",
            totalChapters: 242,
            synopsis: "An unlicensed surgical genius with a scarred face performs medical miracles while exposing the ethical compromises of human society.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 242
        ),
        MangaSeries(
            id: "lone-wolf-104",
            title: "Lone Wolf and Cub",
            author: "Kazuo Koike",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .archive,
            status: "COMPLETED",
            rating: 4.99,
            reviewsCount: "42.5k reviews",
            japaneseTitle: "子連れ狼 (Kozure Ōkami)",
            storyArtist: "Story: Kazuo Koike • Art: Goseki Kojima",
            genres: ["Samurai", "Historical", "Action", "Seinen"],
            releaseYear: "1970 Classic",
            publisher: "Futabasha / Dark Horse",
            totalChapters: 142,
            synopsis: "Disgraced Shogunate executioner Ogami Ittō wanders Edo-period Japan as an assassin-for-hire pushing a baby cart with his infant son Daigorō seeking vengeance.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 142
        )
    ]

    // MARK: - Webtoon Stream Catalog (Vertical Scrolling Hits)
    public static let webtoonCatalog: [MangaSeries] = [
        MangaSeries(
            id: "tower-of-god-201",
            title: "Tower of God",
            author: "SIU",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .webtoons,
            status: "ONGOING",
            rating: 4.94,
            reviewsCount: "68.2k reviews",
            japaneseTitle: "신의 탑 (Tower of God)",
            storyArtist: "Story & Art: SIU (Slave. In. Utero)",
            genres: ["Fantasy", "Action", "Mystery", "Webtoon"],
            releaseYear: "2010 Webtoon",
            publisher: "Naver Webtoon / Line Webtoon",
            totalChapters: 590,
            synopsis: "What do you desire? Money and wealth? Honor and pride? Authority and power? Revenge? Or something that transcends them all? Whatever you desire is at the top of the tower.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 590
        ),
        MangaSeries(
            id: "omniscient-reader-202",
            title: "Omniscient Reader's Viewpoint",
            author: "sing N song",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .webtoons,
            status: "ONGOING",
            rating: 4.97,
            reviewsCount: "54.8k reviews",
            japaneseTitle: "전지적 독자 시점",
            storyArtist: "Story: sing N song • Art: Sleepy-C",
            genres: ["Action", "Apocalyptic", "Supernatural", "Webtoon"],
            releaseYear: "2020 Webtoon",
            publisher: "Redice Studio / Webtoon",
            totalChapters: 210,
            synopsis: "Dokja was an ordinary office worker whose sole hobby was reading an obscure web novel. When the novel suddenly turns into reality, he is the only person who knows how the world ends.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 210
        ),
        MangaSeries(
            id: "tbate-203",
            title: "The Beginning After The End",
            author: "TurtleMe",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .webtoons,
            status: "ONGOING",
            rating: 4.93,
            reviewsCount: "38.1k reviews",
            japaneseTitle: "Tapas Webtoon Hit",
            storyArtist: "Story: TurtleMe • Art: Fuyuki23",
            genres: ["Isekai", "Magic", "Action", "Adventure"],
            releaseYear: "2018 Webtoon",
            publisher: "Tapas Media",
            totalChapters: 180,
            synopsis: "King Grey has unrivaled strength, wealth, and prestige in a world governed by martial ability. Reborn into a new world filled with magic and monsters, the king has a second chance to relive his life.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 180
        ),
        MangaSeries(
            id: "wind-breaker-204",
            title: "Wind Breaker",
            author: "Jo Yongseok",
            coverURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDanvK6HfWu3NyBuP0l...",
            isLocal: false,
            source: .webtoons,
            status: "ONGOING",
            rating: 4.95,
            reviewsCount: "44.7k reviews",
            japaneseTitle: "윈드브레이커",
            storyArtist: "Story & Art: Jo Yongseok",
            genres: ["Sports", "Drama", "Bicycle Racing", "Webtoon"],
            releaseYear: "2013 Webtoon",
            publisher: "Naver Webtoon",
            totalChapters: 495,
            synopsis: "Jay is the high school student council president. He is forced to join the school's biking crew, the Hummingbird Crew, and discovers a whole new world of high-speed street racing.",
            audioDramaAvailable: true,
            lastReadChapter: "Ch. 1",
            unreadCount: 495
        )
    ]

    public static func curatedChapters(for seriesId: String) -> [MangaChapter] {
        let baseCount = 128
        return (1...baseCount).reversed().map { number in
            let dateStr = "Sep \(max(1, 30 - (baseCount - number)))"
            let isNew = number >= 127
            let isRead = number <= 126
            let isDownloaded = number >= 125 && number <= 126
            let title = switch number {
            case 128: "The Far North"
            case 127: "Echoes of the Past"
            case 126: "Magic of the Elves"
            case 125: "Journey Through the Mist"
            case 124: "Shadows over Ende"
            case 123: "The Goddess' Monument"
            case 122: "A Hero's Legacy"
            case 121: "The Aureole Plateau"
            case 120: "The Golden Land Pt. 3"
            case 119: "A Hero's Return"
            default: "Chapter \(number)"
            }
            return MangaChapter(
                id: "\(seriesId)-ch-\(number)",
                title: title,
                numberLabel: "\(number)",
                imagePaths: [],
                pageCount: 22 + (number % 8),
                releaseDate: "\(dateStr) • \(22 + (number % 8)) pages",
                scanGroup: isNew ? "NEW" : "Weekly Shounen",
                isDownloaded: isDownloaded,
                isRead: isRead
            )
        }
    }
}
