import Foundation

public struct DailyListeningRecord: Codable, Sendable {
    public let dateString: String // "yyyy-MM-dd"
    public var minutes: Int
}

public struct UserListeningStats: Codable, Sendable {
    public var streakDays: Int
    public var lastListenDate: String?
    public var totalMinutesListened: Int
    public var dailyTargetMinutes: Int
    public var dailyHistory: [String: Int] // "yyyy-MM-dd" -> minutes

    public init(
        streakDays: Int = 0,
        lastListenDate: String? = nil,
        totalMinutesListened: Int = 0,
        dailyTargetMinutes: Int = 30,
        dailyHistory: [String: Int] = [:]
    ) {
        self.streakDays = streakDays
        self.lastListenDate = lastListenDate
        self.totalMinutesListened = totalMinutesListened
        self.dailyTargetMinutes = dailyTargetMinutes
        self.dailyHistory = dailyHistory
    }
}

public final class StorageService: @unchecked Sendable {
    public static let shared = StorageService()

    private let userDefaults: UserDefaults
    private let bookmarksKey = "AudioBy.Bookmarks"
    private let favoritesKey = "AudioBy.Favorites"
    private let progressKey = "AudioBy.Progress"
    private let statsKey = "AudioBy.ListeningStats"

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

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

    public struct ProgressData: Codable, Sendable {
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

    public func loadAllProgress() -> [String: ProgressData] {
        guard let data = userDefaults.data(forKey: progressKey),
              let dict = try? JSONDecoder().decode([String: ProgressData].self, from: data) else {
            return [:]
        }
        return dict
    }

    // MARK: - Listening Stats & Streaks

    public func loadStats() -> UserListeningStats {
        guard let data = userDefaults.data(forKey: statsKey),
              let stats = try? JSONDecoder().decode(UserListeningStats.self, from: data) else {
            return UserListeningStats()
        }
        return stats
    }

    public func saveStats(_ stats: UserListeningStats) {
        if let data = try? JSONEncoder().encode(stats) {
            userDefaults.set(data, forKey: statsKey)
        }
    }

    public func recordListeningSeconds(_ seconds: TimeInterval) {
        guard seconds >= 5 else { return }
        var stats = loadStats()
        let todayStr = dateFormatter.string(from: Date())

        let addedMinutes = max(1, Int(seconds / 60))
        stats.totalMinutesListened += addedMinutes

        let currentDayMins = stats.dailyHistory[todayStr] ?? 0
        stats.dailyHistory[todayStr] = currentDayMins + addedMinutes

        // Check streak
        if let lastDateStr = stats.lastListenDate, let lastDate = dateFormatter.date(from: lastDateStr) {
            let calendar = Calendar.current
            if !calendar.isDateInToday(lastDate) {
                if calendar.isDateInYesterday(lastDate) {
                    stats.streakDays += 1
                } else {
                    stats.streakDays = 1
                }
            }
        } else {
            stats.streakDays = 1
        }
        stats.lastListenDate = todayStr
        saveStats(stats)
    }
}
