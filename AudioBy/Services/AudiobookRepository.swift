import Foundation
import Observation

@Observable
public final class AudiobookRepository: @unchecked Sendable {
    public static let shared = AudiobookRepository()

    public var audiobooks: [Audiobook] = []
    public var selectedCategory: AudiobookCategory = .all
    public var searchQuery: String = ""

    private let storage = StorageService.shared

    public init() {
        loadInitialData()
    }

    public func loadInitialData() {
        let sample1 = Audiobook(
            id: "book-1",
            title: "The Art of Innovation",
            author: "Elena Rostova",
            narrator: "Samantha Vance",
            summary: "An exhilarating exploration of modern breakthrough thinking, deep tech transformations, and the creative habits of world-changing minds.",
            coverGradientColors: ["#4A00E0", "#8E2DE2"],
            category: .technology,
            rating: 4.9,
            reviewCount: 428,
            chapters: [
                Chapter(
                    id: "c1-1",
                    title: "Chapter 1: The Sparks of Observation",
                    chapterNumber: 1,
                    startTime: 0,
                    duration: 35.0,
                    audioResourceName: "sample_chapter1"
                ),
                Chapter(
                    id: "c1-2",
                    title: "Chapter 2: The Creative Engine",
                    chapterNumber: 2,
                    startTime: 0,
                    duration: 34.0,
                    audioResourceName: "sample_chapter2"
                )
            ]
        )

        let sample2 = Audiobook(
            id: "book-2",
            title: "Echoes of Eternity",
            author: "Marcus Vance",
            narrator: "Karen Sterling",
            summary: "A thrilling sci-fi odyssey across uncharted galaxies, ancient interstellar monoliths, and the philosophical search for human consciousness.",
            coverGradientColors: ["#FF416C", "#FF4B2B"],
            category: .fiction,
            rating: 4.8,
            reviewCount: 812,
            chapters: [
                Chapter(
                    id: "c2-1",
                    title: "Chapter 1: The Starward Call",
                    chapterNumber: 1,
                    startTime: 0,
                    duration: 28.0,
                    audioResourceName: "sample_chapter3"
                ),
                Chapter(
                    id: "c2-2",
                    title: "Chapter 2: Orbit of the Unknown",
                    chapterNumber: 2,
                    startTime: 0,
                    duration: 32.0,
                    audioResourceName: "sample_chapter1"
                )
            ]
        )

        let sample3 = Audiobook(
            id: "book-3",
            title: "Zero to Unstoppable",
            author: "David Sterling",
            narrator: "Michael Vance",
            summary: "Mastering high-performance leadership, resilient habits, and scalable execution in high-stakes environments.",
            coverGradientColors: ["#00F260", "#0575E6"],
            category: .business,
            rating: 4.7,
            reviewCount: 310,
            chapters: [
                Chapter(
                    id: "c3-1",
                    title: "Chapter 1: The Mindset Shift",
                    chapterNumber: 1,
                    startTime: 0,
                    duration: 35.0,
                    audioResourceName: "sample_chapter2"
                ),
                Chapter(
                    id: "c3-2",
                    title: "Chapter 2: Compounding Momentum",
                    chapterNumber: 2,
                    startTime: 0,
                    duration: 30.0,
                    audioResourceName: "sample_chapter1"
                )
            ]
        )

        let sample4 = Audiobook(
            id: "book-4",
            title: "The Architecture of Quiet",
            author: "Dr. Alicia Zhou",
            narrator: "Samantha Vance",
            summary: "Discovering stoic wisdom, cognitive clarity, and mental sanctuaries in an era of hyper-connectivity and endless noise.",
            coverGradientColors: ["#8A2387", "#E94057"],
            category: .philosophy,
            rating: 4.9,
            reviewCount: 560,
            chapters: [
                Chapter(
                    id: "c4-1",
                    title: "Chapter 1: Stillness in Chaos",
                    chapterNumber: 1,
                    startTime: 0,
                    duration: 34.0,
                    audioResourceName: "sample_chapter1"
                ),
                Chapter(
                    id: "c4-2",
                    title: "Chapter 2: The Art of Focused Attention",
                    chapterNumber: 2,
                    startTime: 0,
                    duration: 35.0,
                    audioResourceName: "sample_chapter2"
                )
            ]
        )

        let sample5 = Audiobook(
            id: "book-5",
            title: "Renaissance Minds",
            author: "Julian Reynolds",
            narrator: "Daniel Sterling",
            summary: "The untold biographies of history's greatest polymaths, inventors, and architects who shaped our modern civilizations.",
            coverGradientColors: ["#F37335", "#FDC830"],
            category: .biography,
            rating: 4.8,
            reviewCount: 290,
            chapters: [
                Chapter(
                    id: "c5-1",
                    title: "Chapter 1: The Florentine Workshop",
                    chapterNumber: 1,
                    startTime: 0,
                    duration: 33.0,
                    audioResourceName: "sample_chapter2"
                )
            ]
        )

        var books = [sample1, sample2, sample3, sample4, sample5]

        // Hydrate favorites & progress
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

        self.audiobooks = books
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

        return results
    }

    public var continueListeningBooks: [Audiobook] {
        audiobooks.filter { $0.progress > 0 && $0.progress < 0.99 }
    }

    public var favoriteBooks: [Audiobook] {
        audiobooks.filter { $0.isFavorite }
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
