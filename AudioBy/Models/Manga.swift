import Foundation

public enum MangaSource: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All Catalogs"
    case anilist = "AniList"
    case mangadex = "MangaDex"
    case mangahook = "MangaHook"
    case komorebi = "Komorebi Vault"
    case archive = "Vintage Manga & Comics"
    case webtoons = "Webtoon Stream"
    case local = "Local Vault (CBZ/PDF)"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .anilist: return "sparkle.magnifyingglass"
        case .mangadex: return "globe.asia.australia.fill"
        case .mangahook: return "server.rack"
        case .komorebi: return "sparkles"
        case .archive: return "books.vertical.fill"
        case .webtoons: return "rectangle.portrait.and.arrow.forward"
        case .local: return "folder.fill"
        }
    }
}

public struct MangaSeries: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var author: String
    public var coverURL: String?
    public var isLocal: Bool
    public var source: MangaSource

    // Rich editorial metadata (Komorebi / Manga design system)
    public var status: String?
    public var rating: Double?
    public var reviewsCount: String?
    public var japaneseTitle: String?
    public var storyArtist: String?
    public var genres: [String]?
    public var releaseYear: String?
    public var publisher: String?
    public var totalChapters: Int?
    public var synopsis: String?
    public var audioDramaAvailable: Bool?
    public var lastReadChapter: String?
    public var unreadCount: Int?

    public init(
        id: String,
        title: String,
        author: String,
        coverURL: String?,
        isLocal: Bool,
        source: MangaSource = .komorebi,
        status: String? = nil,
        rating: Double? = nil,
        reviewsCount: String? = nil,
        japaneseTitle: String? = nil,
        storyArtist: String? = nil,
        genres: [String]? = nil,
        releaseYear: String? = nil,
        publisher: String? = nil,
        totalChapters: Int? = nil,
        synopsis: String? = nil,
        audioDramaAvailable: Bool? = nil,
        lastReadChapter: String? = nil,
        unreadCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.isLocal = isLocal
        self.source = source
        self.status = status
        self.rating = rating
        self.reviewsCount = reviewsCount
        self.japaneseTitle = japaneseTitle
        self.storyArtist = storyArtist
        self.genres = genres
        self.releaseYear = releaseYear
        self.publisher = publisher
        self.totalChapters = totalChapters
        self.synopsis = synopsis
        self.audioDramaAvailable = audioDramaAvailable
        self.lastReadChapter = lastReadChapter
        self.unreadCount = unreadCount
    }
}

public struct MangaChapter: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var numberLabel: String
    public var imagePaths: [String]
    public var pageCount: Int?
    public var releaseDate: String?
    public var scanGroup: String?
    public var isDownloaded: Bool?
    public var isRead: Bool?
    /// Official/external reader URL (e.g. MangaPlus) when MangaDex does not host pages.
    public var externalURL: String?

    public var isExternallyHosted: Bool {
        !(externalURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    public init(
        id: String,
        title: String,
        numberLabel: String,
        imagePaths: [String] = [],
        pageCount: Int? = nil,
        releaseDate: String? = nil,
        scanGroup: String? = nil,
        isDownloaded: Bool? = nil,
        isRead: Bool? = nil,
        externalURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.numberLabel = numberLabel
        self.imagePaths = imagePaths
        self.pageCount = pageCount
        self.releaseDate = releaseDate
        self.scanGroup = scanGroup
        self.isDownloaded = isDownloaded
        self.isRead = isRead
        self.externalURL = externalURL
    }
}

public struct StoredManga: Identifiable, Codable, Hashable, Sendable {
    public var series: MangaSeries
    public var chapters: [MangaChapter]

    public var id: String { series.id }

    public init(series: MangaSeries, chapters: [MangaChapter]) {
        self.series = series
        self.chapters = chapters
    }
}

public struct MangaProgress: Codable, Sendable {
    public var chapterId: String
    public var page: Int
    public var vertical: Bool

    public init(chapterId: String, page: Int, vertical: Bool) {
        self.chapterId = chapterId
        self.page = page
        self.vertical = vertical
    }
}
