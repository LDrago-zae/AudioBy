import Foundation

@Observable
public final class MangaLibrary {
    public static let shared = MangaLibrary()
    public private(set) var imported: [StoredManga] = []
    public private(set) var opened: [MangaSeries] = []
    public private(set) var recentSearches: [String] = []
    public var progress: [String: MangaProgress] = [:]

    private let fileURL: URL
    private let openedURL: URL
    private let progressKey = "AudioBy.MangaProgress"
    private let searchesKey = "AudioBy.MangaSearches"

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
        }
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let saved = try? JSONDecoder().decode([String: MangaProgress].self, from: data) {
            progress = saved
        }
        recentSearches = UserDefaults.standard.stringArray(forKey: searchesKey) ?? []
    }

    public func noteOpened(_ series: MangaSeries) {
        opened.removeAll { $0.id == series.id }
        opened.insert(series, at: 0)
        opened = Array(opened.prefix(24))
        if let data = try? JSONEncoder().encode(opened) {
            try? data.write(to: openedURL, options: .atomic)
        }
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
        imported.first { $0.id == id }?.series ?? opened.first { $0.id == id }
    }

    public func add(_ item: StoredManga) {
        imported.removeAll { $0.id == item.id }
        imported.insert(item, at: 0)
        persist()
    }

    public func remember(seriesId: String, chapterId: String, page: Int, vertical: Bool) {
        progress[seriesId] = MangaProgress(chapterId: chapterId, page: page, vertical: vertical)
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
