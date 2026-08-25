import Foundation

public final class StorageService: @unchecked Sendable {
    public static let shared = StorageService()

    private let userDefaults: UserDefaults
    private let bookmarksKey = "AudioBy.Bookmarks"
    private let favoritesKey = "AudioBy.Favorites"
    private let progressKey = "AudioBy.Progress"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Bookmarks

    public func saveBookmarks(_ bookmarks: [Bookmark]) {
        if let data = try? JSONEncoder().encode(bookmarks) {
            userDefaults.set(data, forKey: bookmarksKey)
        }
    }

    public func loadBookmarks() -> [Bookmark] {
        guard let data = userDefaults.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else {
            return []
        }
        return bookmarks
    }

    // MARK: - Favorites

    public func saveFavorites(_ favoriteIds: Set<String>) {
        let array = Array(favoriteIds)
        userDefaults.set(array, forKey: favoritesKey)
    }

    public func loadFavorites() -> Set<String> {
        let array = userDefaults.stringArray(forKey: favoritesKey) ?? []
        return Set(array)
    }

    // MARK: - Progress

    public struct ProgressData: Codable {
        public let chapterIndex: Int
        public let position: TimeInterval
        public let progressRatio: Double
        public let lastUpdated: Date
    }

    public func saveProgress(bookId: String, chapterIndex: Int, position: TimeInterval, progressRatio: Double) {
        var allProgress = loadAllProgress()
        allProgress[bookId] = ProgressData(
            chapterIndex: chapterIndex,
            position: position,
            progressRatio: progressRatio,
            lastUpdated: Date()
        )
        if let data = try? JSONEncoder().encode(allProgress) {
            userDefaults.set(data, forKey: progressKey)
        }
    }

    public func loadProgress(for bookId: String) -> ProgressData? {
        return loadAllProgress()[bookId]
    }

    private func loadAllProgress() -> [String: ProgressData] {
        guard let data = userDefaults.data(forKey: progressKey),
              let dict = try? JSONDecoder().decode([String: ProgressData].self, from: data) else {
            return [:]
        }
        return dict
    }
}
