import Foundation
import Observation

public enum DurationFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "Any Length"
    case short = "< 1 hour"
    case medium = "1 - 3 hours"
    case long = "3 - 6 hours"
    case epic = "6+ hours"

    public var id: String { rawValue }
}

@Observable
public final class AudiobookRepository: @unchecked Sendable {
    public static let shared = AudiobookRepository()

    public var audiobooks: [Audiobook] = []
    public var selectedCategory: AudiobookCategory = .all
    public var selectedDurationFilter: DurationFilter = .all
    public var searchQuery: String = ""
    public var isOnlyDownloadedFilterActive: Bool = false
    public var isLoadingRemote: Bool = false
    public var catalogError: String?
    public var isShowingCachedCatalog: Bool = false
    public var chapterErrors: [String: String] = [:]
    public var loadingChapterBookIds: Set<String> = []

    private let storage = StorageService.shared
    private let api = AudiobookAPIService.shared
    private let downloadManager = DownloadManager.shared
    private let catalogCacheKey = "AudioBy.LastLiveCatalog"

    public init() {
        restoreCachedCatalog()
        Task {
            await fetchRemoteAudiobooks()
        }
    }

    public func fetchRemoteAudiobooks(for category: AudiobookCategory? = nil) async {
        await MainActor.run {
            self.isLoadingRemote = true
            self.catalogError = nil
        }

        let cat = category ?? selectedCategory
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let remoteBooks = try await api.fetchAudiobooks(
                query: query.isEmpty ? nil : query,
                category: cat,
                limit: 40
            )
            await MainActor.run {
                var merged = remoteBooks
                for i in 0..<merged.count {
                    if let existing = self.audiobooks.first(where: { $0.id == merged[i].id }), !existing.chapters.isEmpty {
                        merged[i].chapters = existing.chapters
                    }
                }
                for existing in self.audiobooks where existing.isFavorite || existing.progress > 0 || self.downloadManager.isBookDownloaded(existing.id) {
                    if !merged.contains(where: { $0.id == existing.id }) {
                        merged.append(existing)
                    }
                }
                self.hydrateUserData(into: &merged)
                self.audiobooks = merged
                self.isLoadingRemote = false
                self.isShowingCachedCatalog = false
                self.persistCatalog(merged)
            }
        } catch {
            await MainActor.run {
                self.isLoadingRemote = false
                self.catalogError = error.localizedDescription
                if self.audiobooks.isEmpty {
                    self.restoreCachedCatalog()
                    self.isShowingCachedCatalog = !self.audiobooks.isEmpty
                } else {
                    self.isShowingCachedCatalog = true
                }
            }
        }
    }

    public func updateChapters(for bookId: String, chapters: [Chapter]) {
        if let index = audiobooks.firstIndex(where: { $0.id == bookId }) {
            audiobooks[index].chapters = chapters
            persistCatalog(audiobooks)
        }
    }

    @discardableResult
    public func loadLiveChapters(for bookId: String, forceRefresh: Bool = false) async -> [Chapter] {
        guard let index = audiobooks.firstIndex(where: { $0.id == bookId }) else { return [] }
        let book = audiobooks[index]

        await MainActor.run {
            self.loadingChapterBookIds.insert(bookId)
            self.chapterErrors[bookId] = nil
        }

        do {
            let liveChapters = try await api.fetchLiveChapters(for: book, forceRefresh: forceRefresh)
            await MainActor.run {
                if let currentIndex = self.audiobooks.firstIndex(where: { $0.id == bookId }) {
                    self.audiobooks[currentIndex].chapters = liveChapters
                    self.persistCatalog(self.audiobooks)
                }
                self.loadingChapterBookIds.remove(bookId)
                self.chapterErrors[bookId] = nil
                AudioPlayerService.shared.updateChaptersIfCurrent(bookId: bookId, chapters: liveChapters)
            }
            return liveChapters
        } catch {
            await MainActor.run {
                self.loadingChapterBookIds.remove(bookId)
                self.chapterErrors[bookId] = error.localizedDescription
            }
            return []
        }
    }

    public func retryChapters(for bookId: String) async -> [Chapter] {
        api.clearChapterCache(for: bookId)
        return await loadLiveChapters(for: bookId, forceRefresh: true)
    }

    private func persistCatalog(_ books: [Audiobook]) {
        if let data = try? JSONEncoder().encode(Array(books.prefix(60))) {
            UserDefaults.standard.set(data, forKey: catalogCacheKey)
        }
    }

    private func restoreCachedCatalog() {
        guard let data = UserDefaults.standard.data(forKey: catalogCacheKey),
              var books = try? JSONDecoder().decode([Audiobook].self, from: data),
              !books.isEmpty else { return }
        hydrateUserData(into: &books)
        audiobooks = books
        isShowingCachedCatalog = true
    }

    private func hydrateUserData(into books: inout [Audiobook]) {
        let favSet = storage.loadFavorites()
        for i in 0..<books.count {
            let id = books[i].id
            if favSet.contains(id) {
                books[i].isFavorite = true
            }
            if let prog = storage.loadProgress(for: id) {
                books[i].currentChapterIndex = prog.chapterIndex
                books[i].currentPosition = prog.position
                books[i].progress = prog.progressRatio
            }
        }
    }

    public var filteredAudiobooks: [Audiobook] {
        var results = audiobooks

        if selectedCategory != .all {
            results = results.filter { $0.category == selectedCategory }
        }

        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchQuery.lowercased()
            results = results.filter {
                $0.title.lowercased().contains(query) ||
                $0.author.lowercased().contains(query) ||
                $0.narrator.lowercased().contains(query) ||
                $0.summary.lowercased().contains(query)
            }
        }

        switch selectedDurationFilter {
        case .all:
            break
        case .short:
            results = results.filter { $0.totalDuration > 0 && $0.totalDuration < 3600 }
        case .medium:
            results = results.filter { $0.totalDuration >= 3600 && $0.totalDuration < 10800 }
        case .long:
            results = results.filter { $0.totalDuration >= 10800 && $0.totalDuration < 21600 }
        case .epic:
            results = results.filter { $0.totalDuration >= 21600 }
        }

        if isOnlyDownloadedFilterActive {
            results = results.filter { downloadManager.isBookDownloaded($0.id) }
        }

        return results
    }

    public var continueListeningBooks: [Audiobook] {
        audiobooks.filter { $0.progress > 0 && $0.progress < 0.99 }
    }

    public var favoriteBooks: [Audiobook] {
        audiobooks.filter { $0.isFavorite }
    }

    public var downloadedBooks: [Audiobook] {
        audiobooks.filter { downloadManager.isBookDownloaded($0.id) }
    }

    public var finishedBooks: [Audiobook] {
        audiobooks.filter { $0.progress >= 0.99 }
    }

    public var featuredHeroBooks: [Audiobook] {
        Array(filteredAudiobooks.prefix(4))
    }

    public func toggleFavorite(for bookId: String) {
        if let index = audiobooks.firstIndex(where: { $0.id == bookId }) {
            audiobooks[index].isFavorite.toggle()
            var favSet = storage.loadFavorites()
            if audiobooks[index].isFavorite {
                favSet.insert(bookId)
            } else {
                favSet.remove(bookId)
            }
            storage.saveFavorites(favSet)
        }
    }
}
