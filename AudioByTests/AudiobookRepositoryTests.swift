import XCTest
@testable import AudioBy

final class AudiobookRepositoryTests: XCTestCase {

    func testNewRepositoryStartsWithoutDummyCatalog() {
        let repo = AudiobookRepository()
        XCTAssertTrue(repo.audiobooks.allSatisfy { !$0.title.isEmpty })
        XCTAssertFalse(repo.audiobooks.contains { $0.title == "The Sales & Prospecting Playbook" })
    }

    func testPageSizeIsTwenty() {
        XCTAssertEqual(AudiobookRepository.shared.pageSize, 20)
    }

    func testDurationFiltering() {
        let repo = AudiobookRepository()
        repo.selectedDurationFilter = .short
        let filtered = repo.filteredAudiobooks
        XCTAssertTrue(filtered.allSatisfy { $0.totalDuration > 0 && $0.totalDuration < 3600 })
    }

    func testDurationParser() {
        XCTAssertEqual(AudiobookAPIService.parseDuration("90"), 90)
        XCTAssertEqual(AudiobookAPIService.parseDuration("01:19:57"), 4797)
        XCTAssertEqual(AudiobookAPIService.parseDuration("12:30"), 750)
        XCTAssertEqual(AudiobookAPIService.parseDuration(nil), 0)
    }

    func testChapterAudioFileSelectionPrefers64kb() {
        let files = [
            ArchiveFile(name: "ch1.mp3", title: "One", length: "10", format: "VBR MP3"),
            ArchiveFile(name: "ch1_64kb.mp3", title: "One", length: "10", format: "64Kbps MP3"),
            ArchiveFile(name: "ch1_128kb.mp3", title: "One", length: "10", format: "128Kbps MP3"),
            ArchiveFile(name: "ch2_64kb.mp3", title: "Two", length: "12", format: "64Kbps MP3")
        ]
        let selected = AudiobookAPIService.selectChapterAudioFiles(files)
        XCTAssertEqual(selected.count, 2)
        XCTAssertTrue(selected.allSatisfy { $0.name?.contains("_64kb") == true })
    }

    func testGutenbergIdExtraction() {
        let html = "Read along at https://www.gutenberg.org/ebooks/1661 for the original text."
        XCTAssertEqual(AudiobookAPIService.extractGutenbergId(fromHTML: html), 1661)
    }

    func testGutendexQueryStripsPartNumbers() {
        let query = AudiobookAPIService.gutendexQuery(
            title: "The Casebook of Sherlock Holmes Part 1",
            author: "Sir Arthur Conan Doyle"
        )
        XCTAssertFalse(query.lowercased().contains("part 1"))
        XCTAssertTrue(query.lowercased().contains("casebook"))
    }

    func testUsableChapterCacheRejectsEmptyTextWithoutAudio() {
        let placeholder = Chapter(
            id: "c1",
            title: "Loading",
            chapterNumber: 1,
            startTime: 0,
            duration: 10,
            fullText: "short"
        )
        XCTAssertFalse(AudiobookAPIService.isUsableChapterCache([placeholder]))
    }

    func testToggleFavorite() {
        let repo = AudiobookRepository()
        let sample = Audiobook(
            id: "test-fav-1",
            title: "Test Book",
            author: "Author",
            narrator: "Narrator",
            summary: "Summary"
        )
        repo.catalogBooks = [sample]
        repo.toggleFavorite(for: sample.id)
        XCTAssertEqual(repo.catalogBooks.first?.isFavorite, true)
        repo.toggleFavorite(for: sample.id)
        XCTAssertEqual(repo.catalogBooks.first?.isFavorite, false)
    }

    func testPDFChapterSplit() {
        let words = Array(repeating: "word", count: 3200).joined(separator: " ")
        let chapters = UserImportService.shared.splitIntoChapters(words, wordsPerChapter: 1500)
        XCTAssertEqual(chapters.count, 3)
        XCTAssertTrue(chapters.allSatisfy { $0.hasReadableText })
    }

    func testFreePDFCap() {
        XCTAssertEqual(EntitlementService.shared.canImportPDF, EntitlementService.shared.isPlus || EntitlementService.shared.importedPDFCount < 1)
    }
}
