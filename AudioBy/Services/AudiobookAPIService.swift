import Foundation

public enum CatalogSourceKind: String, Sendable {
    case librivox = "LibriVox"
    case gutenberg = "Project Gutenberg"
    case userPDF = "My PDF"
}

/// Fetches public-domain audiobooks from the Internet Archive (LibriVox collection)
/// and optional Gutenberg text for TTS. No bundled dummy catalog.
public final class AudiobookAPIService: @unchecked Sendable {
    public static let shared = AudiobookAPIService()

    private let session: URLSession
    private let userAgent = "AudioBy/2.0 (iOS Public Domain Audiobook App)"

    private var chapterCacheDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("ChapterCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 90
            config.waitsForConnectivity = true
            config.requestCachePolicy = .reloadRevalidatingCacheData
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Catalog

    public func fetchAudiobooks(
        query: String? = nil,
        category: AudiobookCategory = .all,
        limit: Int = 30,
        offset: Int = 0
    ) async throws -> [Audiobook] {
        var results: [Audiobook] = []
        var lastError: Error?

        do {
            results = try await fetchFromInternetArchive(
                query: query,
                category: category,
                limit: limit,
                offset: offset
            )
        } catch {
            lastError = error
        }

        let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if results.isEmpty, !trimmedQuery.isEmpty {
            let gutenberg = await fetchFromGutendex(query: trimmedQuery, category: category, limit: limit)
            results.append(contentsOf: gutenberg)
        }

        if results.isEmpty, let lastError {
            throw lastError
        }
        return results
    }

    // MARK: - Chapters

    public func fetchLiveChapters(for book: Audiobook, forceRefresh: Bool = false) async throws -> [Chapter] {
        let cacheFileURL = chapterCacheDirectory.appendingPathComponent("\(book.id).json")

        if forceRefresh {
            try? FileManager.default.removeItem(at: cacheFileURL)
        }

        var audioChapters: [Chapter] = []
        var cachedHasText = false

        if !forceRefresh, let cached = loadCachedChapters(at: cacheFileURL) {
            if cached.contains(where: { $0.hasReadableText }) {
                return cached.map { $0.ensuringTranscript() }
            }
            // Keep audio tracks from cache, but still fetch readable text.
            if cached.contains(where: { $0.remoteAudioURL != nil }) {
                audioChapters = cached
            }
        }

        var archiveMetadata: ArchiveMetadataResponse?
        var audioError: Error?

        if audioChapters.isEmpty, let archiveId = book.archiveIdentifier, !archiveId.isEmpty {
            do {
                let fetched = try await fetchArchiveItem(archiveId: archiveId, bookTitle: book.title)
                archiveMetadata = fetched.metadata
                audioChapters = fetched.chapters
            } catch {
                audioError = error
            }
        } else if let archiveId = book.archiveIdentifier, !archiveId.isEmpty, archiveMetadata == nil {
            archiveMetadata = try? await fetchArchiveMetadata(archiveId: archiveId)
        }

        var textChapters: [Chapter] = []
        var textError: Error?
        do {
            textChapters = try await fetchCompanionTextChapters(
                for: book,
                archiveMetadata: archiveMetadata
            )
        } catch {
            textError = error
        }

        let merged = mergeAudioAndText(audio: audioChapters, text: textChapters)
            .map { $0.ensuringTranscript() }

        if !merged.isEmpty {
            if let data = try? JSONEncoder().encode(merged) {
                try? data.write(to: cacheFileURL, options: .atomic)
            }
            return merged
        }

        if let audioError { throw audioError }
        if let textError { throw textError }
        throw APIServiceError.emptyChapters
    }

    public func clearChapterCache(for bookId: String) {
        let cacheFileURL = chapterCacheDirectory.appendingPathComponent("\(bookId).json")
        try? FileManager.default.removeItem(at: cacheFileURL)
    }

    private func loadCachedChapters(at url: URL) -> [Chapter]? {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let cached = try? JSONDecoder().decode([Chapter].self, from: data),
              Self.isUsableChapterCache(cached) else {
            return nil
        }
        return cached
    }

    static func isUsableChapterCache(_ chapters: [Chapter]) -> Bool {
        guard !chapters.isEmpty else { return false }
        return chapters.contains { chapter in
            chapter.remoteAudioURL != nil || chapter.fullText.trimmingCharacters(in: .whitespacesAndNewlines).count > 80
        }
    }

    // MARK: - Internet Archive catalog

    private func fetchFromInternetArchive(
        query: String?,
        category: AudiobookCategory,
        limit: Int,
        offset: Int
    ) async throws -> [Audiobook] {
        var parts = ["collection:librivoxaudio", "mediatype:audio"]
        if let topic = categoryArchiveClause(category) {
            parts.append(topic)
        }
        if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let sanitized = query
                .replacingOccurrences(of: "\"", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            parts.append("(title:(\(sanitized)) OR creator:(\(sanitized)))")
        }

        var components = URLComponents(string: "https://archive.org/advancedsearch.php")
        components?.queryItems = [
            URLQueryItem(name: "q", value: parts.joined(separator: " AND ")),
            URLQueryItem(name: "fl[]", value: "identifier"),
            URLQueryItem(name: "fl[]", value: "title"),
            URLQueryItem(name: "fl[]", value: "creator"),
            URLQueryItem(name: "fl[]", value: "description"),
            URLQueryItem(name: "fl[]", value: "runtime"),
            URLQueryItem(name: "fl[]", value: "downloads"),
            URLQueryItem(name: "fl[]", value: "subject"),
            URLQueryItem(name: "sort[]", value: "downloads desc"),
            URLQueryItem(name: "rows", value: String(limit)),
            URLQueryItem(name: "page", value: String((offset / max(limit, 1)) + 1)),
            URLQueryItem(name: "output", value: "json")
        ]
        guard let url = components?.url else { throw APIServiceError.invalidURL }

        let data = try await fetchData(from: url)
        let decoded = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)
        let docs = decoded.response?.docs ?? []
        return docs.compactMap { mapArchiveDoc($0, fallbackCategory: category) }
    }

    private func categoryArchiveClause(_ category: AudiobookCategory) -> String? {
        switch category {
        case .all:
            return nil
        case .fiction:
            return "(subject:fiction OR subject:literature OR subject:\"science fiction\" OR subject:mystery)"
        case .philosophy:
            return "(subject:philosophy OR subject:religion OR subject:ethics)"
        case .biography:
            return "(subject:biography OR subject:history OR subject:memoir)"
        case .business:
            return "(subject:economics OR subject:business OR subject:finance OR subject:political)"
        case .technology:
            return "(subject:science OR subject:technology OR subject:astronomy OR subject:physics)"
        }
    }

    private func mapArchiveDoc(_ doc: ArchiveSearchDoc, fallbackCategory: AudiobookCategory) -> Audiobook? {
        guard let identifier = doc.identifier, !identifier.isEmpty else { return nil }
        let title = (doc.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let author = doc.creatorValue.isEmpty ? "LibriVox Volunteers" : doc.creatorValue
        let summary = Self.stripHTML(doc.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = Self.parseDuration(doc.runtime)
        let listens = Int(doc.downloads ?? 0)
        let coverURL = URL(string: "https://archive.org/services/img/\(identifier)")

        return Audiobook(
            id: "ia-\(identifier)",
            title: title,
            author: author,
            narrator: "LibriVox volunteers",
            summary: summary.isEmpty ? "Public-domain audiobook from the LibriVox collection at the Internet Archive." : summary,
            coverGradientColors: ["#0d150f", "#10c76b"],
            coverImageURL: coverURL,
            category: fallbackCategory == .all ? Self.categoryFromSubjects(doc.subjectValue) : fallbackCategory,
            rating: 0,
            reviewCount: 0,
            chapters: [],
            reviews: [],
            archiveIdentifier: identifier,
            catalogSource: CatalogSourceKind.librivox.rawValue,
            listenCount: listens,
            estimatedDuration: duration
        )
    }

    // MARK: - Internet Archive chapter files

    private func fetchArchiveMetadata(archiveId: String) async throws -> ArchiveMetadataResponse {
        guard let url = URL(string: "https://archive.org/metadata/\(archiveId)") else {
            throw APIServiceError.invalidURL
        }
        let data = try await fetchData(from: url)
        return try JSONDecoder().decode(ArchiveMetadataResponse.self, from: data)
    }

    private func fetchArchiveItem(archiveId: String, bookTitle: String) async throws -> (chapters: [Chapter], metadata: ArchiveMetadataResponse) {
        let decoded = try await fetchArchiveMetadata(archiveId: archiveId)
        guard let files = decoded.files, !files.isEmpty else {
            throw APIServiceError.emptyChapters
        }

        let audioFiles = Self.selectChapterAudioFiles(files)
        guard !audioFiles.isEmpty else { throw APIServiceError.emptyChapters }

        var result: [Chapter] = []
        for (idx, file) in audioFiles.enumerated() {
            guard let name = file.name, !name.isEmpty else { continue }
            let chapterNumber = idx + 1
            let title = (file.title?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
                ?? Self.prettyFileTitle(name, fallbackNumber: chapterNumber)
            let duration = Self.parseDuration(file.length)
            guard let listenURL = Self.archiveDownloadURL(identifier: archiveId, fileName: name) else { continue }

            result.append(
                Chapter(
                    id: "\(archiveId)-\(chapterNumber)-\(name.hashValue)",
                    title: title,
                    chapterNumber: chapterNumber,
                    startTime: 0,
                    duration: duration,
                    audioResourceName: nil,
                    remoteAudioURL: listenURL,
                    transcriptSegments: [],
                    fullText: ""
                )
            )
        }

        if result.isEmpty { throw APIServiceError.emptyChapters }
        return (result, decoded)
    }

    private func fetchChaptersFromInternetArchive(archiveId: String, bookTitle: String) async throws -> [Chapter] {
        try await fetchArchiveItem(archiveId: archiveId, bookTitle: bookTitle).chapters
    }

    static func selectChapterAudioFiles(_ files: [ArchiveFile]) -> [ArchiveFile] {
        let mp3 = files.filter { file in
            let name = file.name?.lowercased() ?? ""
            let format = file.format?.lowercased() ?? ""
            let isMp3 = name.hasSuffix(".mp3") || format.contains("mp3")
            let isJunk = name.contains(".zip") || name.contains("_vbr.m3u") || name.hasSuffix(".m3u")
            return isMp3 && !isJunk
        }

        let kb64 = mp3.filter {
            ($0.format ?? "").localizedCaseInsensitiveContains("64Kbps") ||
            ($0.name?.lowercased().contains("_64kb.mp3") == true)
        }
        if kb64.count >= 1 { return kb64.sorted { ($0.name ?? "") < ($1.name ?? "") } }

        let kb128 = mp3.filter {
            ($0.format ?? "").localizedCaseInsensitiveContains("128Kbps") ||
            ($0.name?.lowercased().contains("_128kb.mp3") == true)
        }
        if kb128.count >= 1 { return kb128.sorted { ($0.name ?? "") < ($1.name ?? "") } }

        let originals = mp3.filter { file in
            let name = file.name?.lowercased() ?? ""
            return !name.contains("_64kb") && !name.contains("_128kb")
        }
        let chosen = originals.isEmpty ? mp3 : originals
        return chosen.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    static func archiveDownloadURL(identifier: String, fileName: String) -> URL? {
        let encodedName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
        return URL(string: "https://archive.org/download/\(identifier)/\(encodedName)")
    }

    static func prettyFileTitle(_ fileName: String, fallbackNumber: Int) -> String {
        var base = fileName
        if let dot = base.lastIndex(of: ".") {
            base = String(base[..<dot])
        }
        base = base.replacingOccurrences(of: "_64kb", with: "")
        base = base.replacingOccurrences(of: "_128kb", with: "")
        base = base.replacingOccurrences(of: "_", with: " ")
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(format: "Chapter %02d", fallbackNumber) : trimmed
    }

    // MARK: - Gutenberg / Gutendex

    public func fetchAndParseGutenbergBook(gutenbergId: Int, customURL: URL? = nil) async throws -> [Chapter] {
        let textURL = customURL ?? URL(string: "https://www.gutenberg.org/cache/epub/\(gutenbergId)/pg\(gutenbergId).txt")
        guard let url = textURL else { throw APIServiceError.invalidURL }
        return try await fetchAndParseTextFromURL(url, bookTitle: "Gutenberg Book \(gutenbergId)")
    }

    private func fetchCompanionTextChapters(
        for book: Audiobook,
        archiveMetadata: ArchiveMetadataResponse?
    ) async throws -> [Chapter] {
        if let gid = book.gutenbergId ?? extractGutenbergId(from: book.id), gid > 0 {
            return try await fetchAndParseGutenbergBook(gutenbergId: gid, customURL: book.textURL)
        }
        if let textURL = book.textURL {
            return try await fetchAndParseTextFromURL(textURL, bookTitle: book.title)
        }

        let description = archiveMetadata?.metadata?.description ?? book.summary
        if let gid = Self.extractGutenbergId(fromHTML: description) {
            return try await fetchAndParseGutenbergBook(gutenbergId: gid)
        }

        if let catalogURL = Self.librivoxCatalogURL(fromHTML: description) {
            if let html = try? await fetchHTML(catalogURL), let gid = Self.extractGutenbergId(fromHTML: html) {
                return try await fetchAndParseGutenbergBook(gutenbergId: gid)
            }
        }

        if let gid = await lookupGutenbergId(title: book.title, author: book.author) {
            return try await fetchAndParseGutenbergBook(gutenbergId: gid)
        }

        if let archiveId = book.archiveIdentifier, let files = archiveMetadata?.files {
            if let textFile = Self.selectPlainTextFile(files),
               let url = Self.archiveDownloadURL(identifier: archiveId, fileName: textFile.name ?? "") {
                return try await fetchAndParseTextFromURL(url, bookTitle: book.title)
            }
        }

        throw APIServiceError.emptyChapters
    }

    private func lookupGutenbergId(title: String, author: String) async -> Int? {
        let query = Self.gutendexQuery(title: title, author: author)
        guard !query.isEmpty else { return nil }

        var components = URLComponents(string: "https://gutendex.com/books")
        components?.queryItems = [
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "languages", value: "en")
        ]
        guard let url = components?.url else { return nil }

        do {
            let data = try await fetchData(from: url)
            let decoded = try JSONDecoder().decode(GutendexResponse.self, from: data)
            let needle = Self.normalizedTitle(title)
            let candidates = decoded.results ?? []
            let ranked = candidates.compactMap { item -> (Int, Int)? in
                guard let id = item.id, let candidateTitle = item.title else { return nil }
                let score = Self.titleSimilarity(needle, Self.normalizedTitle(candidateTitle))
                return (id, score)
            }
            .sorted { $0.1 > $1.1 }

            guard let best = ranked.first, best.1 >= 45 else { return nil }
            return best.0
        } catch {
            return nil
        }
    }

    private func fetchHTML(_ url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIServiceError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? ""
    }

    private func fetchFromGutendex(query: String?, category: AudiobookCategory, limit: Int) async -> [Audiobook] {
        var components = URLComponents(string: "https://gutendex.com/books")
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "languages", value: "en")]
        if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: query))
        } else if category != .all {
            queryItems.append(URLQueryItem(name: "topic", value: categoryToTopic(category)))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { return [] }

        do {
            let data = try await fetchData(from: url)
            let decoded = try JSONDecoder().decode(GutendexResponse.self, from: data)
            return (decoded.results ?? []).prefix(limit).compactMap { mapGutendexBook($0, fallbackCategory: category) }
        } catch {
            return []
        }
    }

    private func categoryToTopic(_ category: AudiobookCategory) -> String {
        switch category {
        case .all: return ""
        case .fiction: return "fiction"
        case .technology: return "science"
        case .business: return "economics"
        case .philosophy: return "philosophy"
        case .biography: return "biography"
        }
    }

    private func mapGutendexBook(_ item: GutendexBook, fallbackCategory: AudiobookCategory) -> Audiobook? {
        guard let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return nil }
        let gutenbergId = item.id ?? 0
        let id = "gutendex-\(gutenbergId)"
        let author = item.authors?.first?.name?.replacingOccurrences(of: ",", with: "") ?? "Unknown author"
        let coverURL = item.formats?["image/jpeg"].flatMap { URL(string: $0) }
        let summary = item.summaries?.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let textURLString = item.formats?["text/plain; charset=utf-8"]
            ?? item.formats?["text/plain; charset=us-ascii"]
            ?? item.formats?["text/plain"]
            ?? (gutenbergId > 0 ? "https://www.gutenberg.org/cache/epub/\(gutenbergId)/pg\(gutenbergId).txt" : nil)
        let textURL = textURLString.flatMap { URL(string: $0) }

        return Audiobook(
            id: id,
            title: title,
            author: author,
            narrator: "On-device voice",
            summary: summary,
            coverGradientColors: ["#0d150f", "#10c76b"],
            coverImageURL: coverURL,
            category: fallbackCategory == .all ? .fiction : fallbackCategory,
            rating: 0,
            reviewCount: 0,
            chapters: [],
            reviews: [],
            gutenbergId: gutenbergId > 0 ? gutenbergId : nil,
            textURL: textURL,
            catalogSource: CatalogSourceKind.gutenberg.rawValue,
            listenCount: 0,
            estimatedDuration: 0
        )
    }

    private func fetchAndParseTextFromURL(_ url: URL, bookTitle: String) async throws -> [Chapter] {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIServiceError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        guard var fullText = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii),
              fullText.count > 200 else {
            throw APIServiceError.emptyChapters
        }

        if let headerRange = fullText.range(of: "*** START OF", options: .caseInsensitive) {
            fullText = String(fullText[headerRange.upperBound...])
            if let lineBreak = fullText.firstIndex(of: "\n") {
                fullText = String(fullText[fullText.index(after: lineBreak)...])
            }
        }
        if let footerRange = fullText.range(of: "*** END OF", options: .caseInsensitive) {
            fullText = String(fullText[..<footerRange.lowerBound])
        }

        let chapterRegex = try NSRegularExpression(
            pattern: "(?m)^(CHAPTER [0-9IVXLCDM]+|Chapter [0-9IVXLCDM]+|LETTER [0-9IVXLCDM]+|Letter [0-9IVXLCDM]+|[IVXLCDM]+\\.\\s+[A-Z])",
            options: []
        )
        let fullNSRange = NSRange(location: 0, length: fullText.utf16.count)
        let matches = chapterRegex.matches(in: fullText, options: [], range: fullNSRange)

        var parsedChapters: [Chapter] = []

        if matches.count >= 2 {
            for i in 0..<matches.count {
                let match = matches[i]
                let start = match.range.location
                let end = (i + 1 < matches.count) ? matches[i + 1].range.location : fullText.utf16.count
                let length = end - start
                guard let range = Range(NSRange(location: start, length: length), in: fullText) else { continue }
                let chapterText = String(fullText[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard chapterText.count > 40 else { continue }

                let chapterTitle: String
                if let titleRange = Range(match.range, in: fullText) {
                    chapterTitle = String(fullText[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    chapterTitle = String(format: "Chapter %02d", i + 1)
                }

                let wordCount = chapterText.split { $0.isWhitespace || $0.isNewline }.count
                let durationSeconds = max(60.0, Double(wordCount) / 150.0 * 60.0)

                parsedChapters.append(
                    Chapter(
                        id: "txt-\(abs(chapterTitle.hashValue))-\(i + 1)",
                        title: chapterTitle,
                        chapterNumber: parsedChapters.count + 1,
                        startTime: 0,
                        duration: durationSeconds,
                        fullText: chapterText
                    )
                )
            }
        }

        if parsedChapters.isEmpty {
            let words = fullText.split { $0.isWhitespace || $0.isNewline }.map(String.init)
            let chunkSize = 1500
            let totalChunks = max(1, (words.count + chunkSize - 1) / chunkSize)
            for chunkIndex in 0..<totalChunks {
                let startWord = chunkIndex * chunkSize
                let endWord = min(startWord + chunkSize, words.count)
                let chunkWords = words[startWord..<endWord]
                let chunkText = chunkWords.joined(separator: " ")
                guard chunkText.count > 40 else { continue }
                let durationSeconds = max(60.0, Double(chunkWords.count) / 150.0 * 60.0)
                parsedChapters.append(
                    Chapter(
                        id: "sec-\(chunkIndex + 1)",
                        title: String(format: "Section %02d", chunkIndex + 1),
                        chapterNumber: chunkIndex + 1,
                        startTime: 0,
                        duration: durationSeconds,
                        fullText: chunkText
                    )
                )
            }
        }

        if parsedChapters.isEmpty { throw APIServiceError.emptyChapters }
        return parsedChapters
    }

    private func mergeAudioAndText(audio: [Chapter], text: [Chapter]) -> [Chapter] {
        if audio.isEmpty { return text.map { $0.ensuringTranscript() } }
        if text.isEmpty { return audio }

        let titleMatched = matchTextChaptersByTitle(audio: audio, text: text)
        if titleMatched.contains(where: { $0.hasReadableText }) {
            return titleMatched
        }

        if abs(audio.count - text.count) <= 2 {
            return audio.enumerated().map { index, existing in
                guard index < text.count else { return existing }
                return existing.replacingText(text[index].fullText)
            }
        }

        let combined = text.map(\.fullText).filter { !$0.isEmpty }.joined(separator: "\n\n")
        if combined.count > 80 {
            return splitTextAcrossAudioChapters(audio: audio, fullText: combined)
        }
        return audio
    }

    private func matchTextChaptersByTitle(audio: [Chapter], text: [Chapter]) -> [Chapter] {
        audio.map { track in
            let audioKey = Self.normalizedTitle(track.title)
            guard audioKey.count > 4 else { return track }
            let best = text.max { lhs, rhs in
                Self.titleSimilarity(audioKey, Self.normalizedTitle(lhs.title))
                    < Self.titleSimilarity(audioKey, Self.normalizedTitle(rhs.title))
            }
            guard let best, Self.titleSimilarity(audioKey, Self.normalizedTitle(best.title)) >= 50 else {
                return track
            }
            return track.replacingText(best.fullText)
        }
    }

    private func splitTextAcrossAudioChapters(audio: [Chapter], fullText: String) -> [Chapter] {
        let paragraphs = fullText
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !paragraphs.isEmpty else { return audio }

        let totalDuration = max(audio.reduce(0) { $0 + max($1.duration, 1) }, 1)
        var cursor = 0
        let totalParagraphs = paragraphs.count

        return audio.enumerated().map { index, track in
            let share = max(track.duration, 1) / totalDuration
            var take = max(1, Int((share * Double(totalParagraphs)).rounded()))
            if index == audio.count - 1 {
                take = max(1, totalParagraphs - cursor)
            }
            let end = min(totalParagraphs, cursor + take)
            let slice = paragraphs[cursor..<end].joined(separator: "\n\n")
            cursor = end
            return track.replacingText(slice)
        }
    }

    // MARK: - Networking helpers

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIServiceError.badStatus(http.statusCode) }
        return data
    }

    private func extractGutenbergId(from bookId: String) -> Int? {
        if bookId.hasPrefix("gutendex-") {
            return Int(bookId.replacingOccurrences(of: "gutendex-", with: ""))
        }
        return nil
    }

    static func titlesMatch(_ a: String, _ b: String) -> Bool {
        normalizedTitle(a) == normalizedTitle(b)
    }

    static func extractGutenbergId(fromHTML html: String) -> Int? {
        let patterns = [
            #"gutenberg\.org/ebooks/(\d+)"#,
            #"gutenberg\.org/etext/(\d+)"#,
            #"gutenberg\.org/files/(\d+)"#,
            #"gutenberg\.org/cache/epub/(\d+)"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, options: [], range: range),
                   let idRange = Range(match.range(at: 1), in: html),
                   let id = Int(html[idRange]) {
                    return id
                }
            }
        }
        return nil
    }

    static func librivoxCatalogURL(fromHTML html: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: #"https?://librivox\.org/[^\s\"'<>]+"#, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        for match in matches {
            guard let swiftRange = Range(match.range, in: html) else { continue }
            let value = String(html[swiftRange])
            if value == "https://librivox.org/" || value == "http://librivox.org/" { continue }
            if value.contains("/api/") { continue }
            return URL(string: value)
        }
        return nil
    }

    static func selectPlainTextFile(_ files: [ArchiveFile]) -> ArchiveFile? {
        let ranked = files.compactMap { file -> (ArchiveFile, Int)? in
            let name = file.name?.lowercased() ?? ""
            let format = file.format?.lowercased() ?? ""
            if name.hasSuffix("_meta.txt") || name == "files.xml" || name.hasSuffix(".xml") {
                return nil
            }
            if name.hasSuffix("_djvu.txt") { return (file, 2) }
            if name.hasSuffix(".txt") || format.contains("djvutxt") || format == "text" {
                return (file, 3)
            }
            return nil
        }
        return ranked.max(by: { $0.1 < $1.1 })?.0
    }

    static func gutendexQuery(title: String, author: String) -> String {
        var cleaned = title
        let replacements = [
            #"(?i)^librivox recording of\s+"#,
            #"(?i)\s*\(librivox\)"#,
            #"(?i)\s*part\s*\d+"#,
            #"(?i)\s*volume\s*[ivxlcdm\d]+"#,
            #"(?i)\s*\[.*?\]"#
        ]
        for pattern in replacements {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let authorLast = author.split(separator: " ").last.map {
            String($0).trimmingCharacters(in: CharacterSet(charactersIn: ",."))
        } ?? ""

        if cleaned.isEmpty { return authorLast }
        if authorLast.count > 2, !cleaned.lowercased().contains(authorLast.lowercased()) {
            return "\(cleaned) \(authorLast)"
        }
        return cleaned
    }

    static func normalizedTitle(_ value: String) -> String {
        var text = value.lowercased()
        text = text.replacingOccurrences(of: #"^(the|a|an)\s+"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func titleSimilarity(_ a: String, _ b: String) -> Int {
        if a.isEmpty || b.isEmpty { return 0 }
        if a == b { return 100 }
        if a.contains(b) || b.contains(a) { return 80 }
        let left = Set(a.split(separator: " ").map(String.init))
        let right = Set(b.split(separator: " ").map(String.init))
        let intersection = left.intersection(right).count
        let union = max(left.union(right).count, 1)
        return Int((Double(intersection) / Double(union)) * 100)
    }

    static func stripHTML(_ raw: String) -> String {
        var text = raw.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    static func categoryFromSubjects(_ subjects: String) -> AudiobookCategory {
        let s = subjects.lowercased()
        if s.contains("philosoph") || s.contains("ethic") { return .philosophy }
        if s.contains("biograph") || s.contains("history") { return .biography }
        if s.contains("science") || s.contains("technolog") || s.contains("astronom") { return .technology }
        if s.contains("econom") || s.contains("business") || s.contains("politic") { return .business }
        return .fiction
    }

    public static func parseDuration(_ lengthString: String?) -> TimeInterval {
        guard let s = lengthString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return 0
        }
        if let seconds = Double(s) { return seconds }

        let parts = s.components(separatedBy: ":")
        if parts.count == 2, let m = Double(parts[0]), let sec = Double(parts[1]) {
            return m * 60 + sec
        } else if parts.count == 3, let h = Double(parts[0]), let m = Double(parts[1]), let sec = Double(parts[2]) {
            return h * 3600 + m * 60 + sec
        }
        return 0
    }
}

public enum APIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badStatus(Int)
    case emptyChapters
    case emptyCatalog

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build a valid request."
        case .invalidResponse:
            return "The catalog returned an invalid response."
        case .badStatus(let code):
            return "The catalog request failed (\(code))."
        case .emptyChapters:
            return "No chapters or audio files were returned for this title."
        case .emptyCatalog:
            return "No audiobooks were returned. Check your connection and try again."
        }
    }
}

// MARK: - Decodable models

private struct ArchiveSearchResponse: Decodable {
    let response: ArchiveSearchInner?
}

private struct ArchiveSearchInner: Decodable {
    let docs: [ArchiveSearchDoc]?
}

private struct ArchiveSearchDoc: Decodable {
    let identifier: String?
    let title: String?
    let creator: FlexibleString?
    let description: String?
    let runtime: String?
    let downloads: Double?
    let subject: FlexibleString?

    var creatorValue: String { creator?.value ?? "" }
    var subjectValue: String { subject?.value ?? "" }
}

struct ArchiveFile: Decodable {
    let name: String?
    let title: String?
    let length: String?
    let format: String?

    init(name: String?, title: String?, length: String?, format: String?) {
        self.name = name
        self.title = title
        self.length = length
        self.format = format
    }

    enum CodingKeys: String, CodingKey {
        case name, title, length, format
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        if let string = try? container.decode(String.self, forKey: .length) {
            length = string
        } else if let number = try? container.decode(Double.self, forKey: .length) {
            length = String(number)
        } else {
            length = nil
        }
    }
}

private struct ArchiveMetadataResponse: Decodable {
    let files: [ArchiveFile]?
    let metadata: ArchiveItemMetadata?
}

private struct ArchiveItemMetadata: Decodable {
    let description: String?
    let title: String?
}

private struct GutendexResponse: Decodable {
    let results: [GutendexBook]?
}

private struct GutendexBook: Decodable {
    let id: Int?
    let title: String?
    let authors: [GutendexAuthor]?
    let summaries: [String]?
    let formats: [String: String]?
}

private struct GutendexAuthor: Decodable {
    let name: String?
}

private struct FlexibleString: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([String].self) {
            value = array.joined(separator: ", ")
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else {
            value = ""
        }
    }
}
