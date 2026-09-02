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

    func testFTSMatchEscapesUserQuery() {
        let match = CatalogRepository.ftsMatch(from: "Pride & Prejudice")
        XCTAssertTrue(match.contains("\"Pride\"*"))
        XCTAssertTrue(match.contains("\"Prejudice\"*"))
        XCTAssertFalse(match.contains("&"))
    }

    func testLocalCatalogSearchAndPagination() throws {
        let store = CatalogStore()
        try store.openDatabase(at: fixtureCatalogURL())
        let repo = CatalogRepository(store: store)
        let first = try repo.page(query: nil, category: .all, limit: 20, offset: 0)
        XCTAssertEqual(first.count, 20)
        let second = try repo.page(query: nil, category: .all, limit: 20, offset: 20)
        XCTAssertFalse(second.isEmpty)
        let overlap = Set(first.map(\.id)).intersection(Set(second.map(\.id)))
        XCTAssertTrue(overlap.isEmpty)

        let pride = try repo.page(query: "Pride Prejudice", category: .all, limit: 10, offset: 0)
        XCTAssertTrue(pride.contains { $0.title.localizedCaseInsensitiveContains("Pride") })
        XCTAssertTrue(pride.allSatisfy { $0.gutenbergId != nil })
    }

    func testContentCacheGutenbergFallbackOrder() async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("BookCache-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        CatalogStubURLProtocol.responses = [
            "/cache/epub/99999/pg99999.txt": (404, Data()),
            "/files/99999/99999-0.txt": (200, Data(repeating: 65, count: 250))
        ]
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [CatalogStubURLProtocol.self]
        let session = URLSession(configuration: config)
        let cache = ContentCache(paths: BookCachePaths(baseDirectory: temp), session: session)
        let text = try await cache.fetchText(for: 99999)
        XCTAssertEqual(text.count, 250)
        XCTAssertTrue(FileManager.default.fileExists(atPath: BookCachePaths(baseDirectory: temp).textFileURL(forKey: "99999").path))
    }

    func testGutenbergTextURLFallbacks() {
        let urls = ContentCache.gutenbergTextURLs(id: 11).map(\.absoluteString)
        XCTAssertEqual(urls.first, "https://www.gutenberg.org/cache/epub/11/pg11.txt")
        XCTAssertTrue(urls.contains("https://www.gutenberg.org/files/11/11-0.txt"))
        XCTAssertTrue(urls.contains("https://www.gutenberg.org/files/11/11.txt"))
        XCTAssertTrue(urls.contains("https://www.gutenberg.org/files/11/11-8.txt"))
    }

    private func fixtureCatalogURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("AudioBy/Resources/catalog.fixture.sqlite")
    }
}

final class CatalogStubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [String: (Int, Data)] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path ?? ""
        let match = CatalogStubURLProtocol.responses.first { path.hasSuffix($0.key) || path.contains($0.key) }
        let status = match?.value.0 ?? 404
        let data = match?.value.1 ?? Data()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if status >= 200 && status < 300 {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
