import Foundation

@Observable
public final class MangaLibrary {
    public static let shared = MangaLibrary()
    public private(set) var imported: [StoredManga] = []
    public private(set) var opened: [MangaSeries] = []
    public private(set) var recentSearches: [String] = []
    public var progress: [String: MangaProgress] = [:]
    public var bookmarkedIds: Set<String> = ["frieren-001", "chainsaw-man-002"]
    public var readChapterIds: Set<String> = []
    public var downloadedChapterIds: Set<String> = []

    public var streakDays: Int = 14
    public var streakMinutesToday: Int = 48
    public var streakMinutesGoal: Int = 60

    private let fileURL: URL
    private let openedURL: URL
    private let progressKey = "AudioBy.MangaProgress"
    private let searchesKey = "AudioBy.MangaSearches"
    private let bookmarksKey = "AudioBy.MangaBookmarks"
    private let readChaptersKey = "AudioBy.MangaReadChapters"
    private let downloadedChaptersKey = "AudioBy.MangaDownloadedChapters"

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("MangaLibrary.json")
        openedURL = docs.appendingPathComponent("MangaOpened.json")
        if let data = try? Data(contentsOf: fileURL),
           let stored = try? JSONDecoder().decode([StoredManga].self, from: data) {
            imported = stored
        }
        if let data = try? Data(contentsOf: openedURL),
           let stored = try? JSONDecoder().decode([MangaSeries].self, from: data) {
            opened = stored
        } else {
            // Default opened list to prime with curated favorites
            opened = Array(MangaDexService.curatedCatalog.prefix(4))
        }
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let saved = try? JSONDecoder().decode([String: MangaProgress].self, from: data) {
            progress = saved
        }
        recentSearches = UserDefaults.standard.stringArray(forKey: searchesKey) ?? []
        if let savedBookmarks = UserDefaults.standard.stringArray(forKey: bookmarksKey) {
            bookmarkedIds = Set(savedBookmarks)
        }
        if let savedRead = UserDefaults.standard.stringArray(forKey: readChaptersKey) {
            readChapterIds = Set(savedRead)
        }
        if let savedDownloads = UserDefaults.standard.stringArray(forKey: downloadedChaptersKey) {
            downloadedChapterIds = Set(savedDownloads)
        }
    }

    public func isChapterDownloaded(_ chapterId: String) -> Bool {
        downloadedChapterIds.contains(chapterId)
    }

    public func downloadChapter(_ chapter: MangaChapter, series: MangaSeries) {
        _ = MangaPageRenderer.shared.getOrGeneratePages(for: series, chapter: chapter)
        markChapterDownloaded(chapter.id)
    }

    public func markChapterDownloaded(_ chapterId: String) {
        downloadedChapterIds.insert(chapterId)
        UserDefaults.standard.set(Array(downloadedChapterIds), forKey: downloadedChaptersKey)
    }

    public func noteOpened(_ series: MangaSeries) {
        opened.removeAll { $0.id == series.id }
        opened.insert(series, at: 0)
        opened = Array(opened.prefix(24))
        if let data = try? JSONEncoder().encode(opened) {
            try? data.write(to: openedURL, options: .atomic)
        }
    }

    public func isBookmarked(_ seriesId: String) -> Bool {
        bookmarkedIds.contains(seriesId)
    }

    public func toggleBookmark(_ series: MangaSeries) {
        if bookmarkedIds.contains(series.id) {
            bookmarkedIds.remove(series.id)
        } else {
            bookmarkedIds.insert(series.id)
            noteOpened(series)
        }
        UserDefaults.standard.set(Array(bookmarkedIds), forKey: bookmarksKey)
    }

    public func isChapterRead(_ chapterId: String) -> Bool {
        readChapterIds.contains(chapterId)
    }

    public func markChapterRead(_ chapterId: String) {
        readChapterIds.insert(chapterId)
        UserDefaults.standard.set(Array(readChapterIds), forKey: readChaptersKey)
    }

    public func noteSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(8))
        UserDefaults.standard.set(recentSearches, forKey: searchesKey)
    }

    public func clearSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: searchesKey)
    }

    public func series(for id: String) -> MangaSeries? {
        imported.first { $0.id == id }?.series ??
        opened.first { $0.id == id } ??
        MangaDexService.curatedCatalog.first { $0.id == id }
    }

    public func add(_ item: StoredManga) {
        imported.removeAll { $0.id == item.id }
        imported.insert(item, at: 0)
        persist()
    }

    public func remember(seriesId: String, chapterId: String, page: Int, vertical: Bool) {
        progress[seriesId] = MangaProgress(chapterId: chapterId, page: page, vertical: vertical)
        markChapterRead(chapterId)
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(imported) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
