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

    public let pageSize = 20

    public var catalogBooks: [Audiobook] = []
    public var importedBooks: [Audiobook] = []
    public var selectedCategory: AudiobookCategory = .all
    public var selectedDurationFilter: DurationFilter = .all
    public var searchQuery: String = ""
    public var isOnlyDownloadedFilterActive: Bool = false
    public var isLoadingRemote: Bool = false
    public var isLoadingMore: Bool = false
    public var hasMoreCatalog: Bool = true
    public var catalogError: String?
    public var isShowingCachedCatalog: Bool = false
    public var chapterErrors: [String: String] = [:]
    public var loadingChapterBookIds: Set<String> = []

    private var catalogOffset: Int = 0
    private let storage = StorageService.shared
    private let api = AudiobookAPIService.shared
    private let downloadManager = DownloadManager.shared
    private let catalogCacheKey = "AudioBy.LastLiveCatalog"

    public var audiobooks: [Audiobook] {
        mergedBooks()
    }

    public init() {
        restoreCachedCatalog()
        importedBooks = UserImportService.shared.loadImportedBooks()
        Task {
            await fetchRemoteAudiobooks(reset: true)
        }
    }

    public func fetchRemoteAudiobooks(for category: AudiobookCategory? = nil, reset: Bool = true) async {
        if let category {
            selectedCategory = category
        }

        if reset {
            await MainActor.run {
                self.isLoadingRemote = true
                self.isLoadingMore = false
                self.catalogError = nil
                self.catalogOffset = 0
            }
        } else {
            await MainActor.run {
                self.isLoadingMore = true
                self.catalogError = nil
            }
        }

        let cat = selectedCategory
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let offset = reset ? 0 : catalogOffset

        do {
            let remoteBooks = try await api.fetchAudiobooks(
                query: query.isEmpty ? nil : query,
                category: cat,
                limit: pageSize,
                offset: offset
            )
            await MainActor.run {
                self.applyFetchedPage(remoteBooks, reset: reset, offset: offset)
            }
        } catch {
            await MainActor.run {
                self.isLoadingRemote = false
                self.isLoadingMore = false
                self.catalogError = error.localizedDescription
                if self.catalogBooks.isEmpty {
                    self.restoreCachedCatalog()
                    self.isShowingCachedCatalog = !self.catalogBooks.isEmpty
                } else {
                    self.isShowingCachedCatalog = true
                }
            }
        }
    }

    public func loadMore() async {
        guard hasMoreCatalog, !isLoadingRemote, !isLoadingMore else { return }
        await fetchRemoteAudiobooks(reset: false)
    }

    private func applyFetchedPage(_ remoteBooks: [Audiobook], reset: Bool, offset: Int) {
        var page = remoteBooks
        hydrateUserData(into: &page)

        if reset {
            catalogBooks = page
        } else {
            for book in page where !catalogBooks.contains(where: { $0.id == book.id }) {
                catalogBooks.append(book)
            }
        }

        catalogOffset = offset + page.count
        hasMoreCatalog = page.count >= pageSize
        isLoadingRemote = false
        isLoadingMore = false
        isShowingCachedCatalog = false
        persistCatalog(catalogBooks)
    }

    public func updateChapters(for bookId: String, chapters: [Chapter]) {
        if let index = catalogBooks.firstIndex(where: { $0.id == bookId }) {
            catalogBooks[index].chapters = chapters
            persistCatalog(catalogBooks)
        }
        if let index = importedBooks.firstIndex(where: { $0.id == bookId }) {
            importedBooks[index].chapters = chapters
            UserImportService.shared.saveImportedBooks(importedBooks)
        }
    }

    public func upsertImportedBook(_ book: Audiobook) {
        if let index = importedBooks.firstIndex(where: { $0.id == book.id }) {
            importedBooks[index] = book
        } else {
            importedBooks.insert(book, at: 0)
        }
        UserImportService.shared.saveImportedBooks(importedBooks)
    }

    public func removeImportedBook(id: String) {
        importedBooks.removeAll { $0.id == id }
        UserImportService.shared.saveImportedBooks(importedBooks)
        UserImportService.shared.deleteStoredPDF(bookId: id)
    }

    public func book(id: String) -> Audiobook? {
        catalogBooks.first { $0.id == id } ?? importedBooks.first { $0.id == id }
    }

    @discardableResult
    public func loadLiveChapters(for bookId: String, forceRefresh: Bool = false) async -> [Chapter] {
        guard let book = book(id: bookId) else { return [] }
        if book.catalogSource == CatalogSourceKind.userPDF.rawValue {
            return book.chapters
        }

        await MainActor.run {
            self.loadingChapterBookIds.insert(bookId)
            self.chapterErrors[bookId] = nil
        }

        do {
            let liveChapters = try await api.fetchLiveChapters(for: book, forceRefresh: forceRefresh)
            await MainActor.run {
                self.updateChapters(for: bookId, chapters: liveChapters)
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
        if let data = try? JSONEncoder().encode(Array(books.prefix(80))) {
            UserDefaults.standard.set(data, forKey: catalogCacheKey)
        }
    }

    private func restoreCachedCatalog() {
        guard let data = UserDefaults.standard.data(forKey: catalogCacheKey),
              var books = try? JSONDecoder().decode([Audiobook].self, from: data),
              !books.isEmpty else { return }
        hydrateUserData(into: &books)
        catalogBooks = Array(books.prefix(pageSize))
        catalogOffset = catalogBooks.count
        hasMoreCatalog = books.count >= pageSize
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

    private func mergedBooks() -> [Audiobook] {
        var result = catalogBooks
        for book in importedBooks where !result.contains(where: { $0.id == book.id }) {
            result.append(book)
        }
        return result
    }

    private func applyLocalFilters(_ books: [Audiobook], applySearch: Bool) -> [Audiobook] {
        var results = books

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

    public var exploreBooks: [Audiobook] {
        applyLocalFilters(catalogBooks, applySearch: false)
    }

    public var filteredAudiobooks: [Audiobook] {
        applyLocalFilters(catalogBooks, applySearch: false)
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
        Array(exploreBooks.prefix(4))
    }

    public func toggleFavorite(for bookId: String) {
        func toggle(in books: inout [Audiobook]) -> Bool? {
            guard let index = books.firstIndex(where: { $0.id == bookId }) else { return nil }
            books[index].isFavorite.toggle()
            return books[index].isFavorite
        }

        let newValue = toggle(in: &catalogBooks) ?? toggle(in: &importedBooks)
        guard let newValue else { return }
        var favSet = storage.loadFavorites()
        if newValue {
            favSet.insert(bookId)
        } else {
            favSet.remove(bookId)
        }
        storage.saveFavorites(favSet)
        persistCatalog(catalogBooks)
    }
}
