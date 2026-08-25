import XCTest
@testable import AudioBy

final class AudiobookRepositoryTests: XCTestCase {

    func testInitialRepositoryHasAudiobooks() {
        let repo = AudiobookRepository()
        XCTAssertFalse(repo.audiobooks.isEmpty)
    }

    func testSearchFiltering() {
        let repo = AudiobookRepository()
        repo.searchQuery = "Innovation"
        let filtered = repo.filteredAudiobooks
        XCTAssertTrue(filtered.allSatisfy { $0.title.contains("Innovation") || $0.summary.contains("Innovation") })
    }

    func testCategoryFiltering() {
        let repo = AudiobookRepository()
        repo.selectedCategory = .business
        let filtered = repo.filteredAudiobooks
        XCTAssertTrue(filtered.allSatisfy { $0.category == .business })
    }

    func testToggleFavorite() {
        let repo = AudiobookRepository()
        guard let firstBook = repo.audiobooks.first else {
            XCTFail("No books in repository")
            return
        }

        let initialFav = firstBook.isFavorite
        repo.toggleFavorite(for: firstBook.id)

        let updatedBook = repo.audiobooks.first { $0.id == firstBook.id }
        XCTAssertEqual(updatedBook?.isFavorite, !initialFav)
    }
}
