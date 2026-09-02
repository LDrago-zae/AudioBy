import Foundation

public struct BookCachePaths: Sendable {
    public let baseDirectory: URL

    public init(baseDirectory: URL? = nil, fileManager: FileManager = .default) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.baseDirectory = support.appendingPathComponent("BookCache", isDirectory: true)
        }
        try? fileManager.createDirectory(at: self.baseDirectory, withIntermediateDirectories: true)
    }

    public static let `default` = BookCachePaths()

    public static func cacheKey(for book: Audiobook) -> String {
        cacheKey(bookId: book.id, gutenbergId: book.gutenbergId)
    }

    public static func cacheKey(bookId: String, gutenbergId: Int? = nil) -> String {
        if let gutenbergId, gutenbergId > 0 {
            return "\(gutenbergId)"
        }
        if bookId.hasPrefix("gutenberg-"), let id = Int(bookId.dropFirst("gutenberg-".count)) {
            return "\(id)"
        }
        return bookId
    }

    public func bookDirectory(forKey key: String) -> URL {
        baseDirectory.appendingPathComponent(key, isDirectory: true)
    }

    public func textFileURL(forKey key: String) -> URL {
        bookDirectory(forKey: key).appendingPathComponent("text.txt")
    }

    public func audioDirectory(forKey key: String) -> URL {
        bookDirectory(forKey: key).appendingPathComponent("audio", isDirectory: true)
    }

    public func chapterAudioURL(forKey key: String, chapterNumber: Int) -> URL {
        audioDirectory(forKey: key).appendingPathComponent("chapter_\(chapterNumber).mp3")
    }

    public func chapterAudioM4AURL(forKey key: String, chapterNumber: Int) -> URL {
        audioDirectory(forKey: key).appendingPathComponent("chapter_\(chapterNumber).m4a")
    }

    public func studioAudioURL(forKey key: String, chapterId: String, voiceId: String) -> URL {
        audioDirectory(forKey: key).appendingPathComponent("studio-\(chapterId)-\(voiceId).mp3")
    }
}

public actor ContentCache {
    public static let shared = ContentCache()

    public static let defaultLimitBytes: Int64 = 2_000_000_000
    public static let limitDefaultsKey = "AudioBy.CacheLimitBytes"

    private let fileManager: FileManager
    private let session: URLSession
    private let userAgent = "AudioBy/2.0 (iOS Public Domain Audiobook App)"
    public let paths: BookCachePaths

    public init(paths: BookCachePaths = .default, session: URLSession = .shared, fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
        self.session = session
        try? fileManager.createDirectory(at: paths.baseDirectory, withIntermediateDirectories: true)
    }

    public func fetchText(for gutenbergId: Int) async throws -> String {
        let key = "\(gutenbergId)"
        let localURL = paths.textFileURL(forKey: key)
        if fileManager.fileExists(atPath: localURL.path),
           let cached = try? String(contentsOf: localURL, encoding: .utf8),
           cached.count > 200 {
            touch(key: key)
            return cached
        }

        var lastError: Error = ContentCacheError.missingText
        for url in Self.gutenbergTextURLs(id: gutenbergId) {
            do {
                let data = try await downloadData(from: url)
                guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii),
                      text.count > 200 else { continue }
                try persistText(text, key: key)
                return text
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    public func persistText(_ text: String, key: String) throws {
        let dir = paths.bookDirectory(forKey: key)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        try text.write(to: paths.textFileURL(forKey: key), atomically: true, encoding: .utf8)
        touch(key: key)
    }

    public func ensureAudioDirectory(forKey key: String) throws -> URL {
        let dir = paths.audioDirectory(forKey: key)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func touch(key: String) {
        var values = URLResourceValues()
        values.contentAccessDate = Date()
        var url = paths.bookDirectory(forKey: key)
        try? url.setResourceValues(values)
    }

    public func removeBook(key: String) {
        try? fileManager.removeItem(at: paths.bookDirectory(forKey: key))
    }

    public func totalBytes() -> Int64 {
        directorySize(paths.baseDirectory)
    }

    public func evictIfNeeded(limitBytes: Int64 = ContentCache.currentLimitBytes()) {
        guard limitBytes > 0 else { return }
        var folders = bookFolders()
        var total = folders.reduce(Int64(0)) { $0 + $1.size }
        guard total > limitBytes else { return }
        folders.sort { $0.accessed < $1.accessed }
        for folder in folders {
            guard total > limitBytes else { break }
            try? fileManager.removeItem(at: folder.url)
            total -= folder.size
        }
    }

    public static func currentLimitBytes() -> Int64 {
        if let number = UserDefaults.standard.object(forKey: limitDefaultsKey) as? NSNumber {
            return number.int64Value
        }
        return defaultLimitBytes
    }

    public static func gutenbergTextURLs(id: Int) -> [URL] {
        let strings = [
            "https://www.gutenberg.org/cache/epub/\(id)/pg\(id).txt",
            "https://www.gutenberg.org/files/\(id)/\(id)-0.txt",
            "https://www.gutenberg.org/files/\(id)/\(id).txt",
            "https://www.gutenberg.org/files/\(id)/\(id)-8.txt"
        ]
        return strings.compactMap(URL.init(string:))
    }

    private func downloadData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ContentCacheError.badStatus(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ContentCacheError.badStatus(http.statusCode)
        }
        return data
    }

    private func directorySize(_ url: URL) -> Int64 {
        var total: Int64 = 0
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
            for case let fileURL as URL in enumerator {
                let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if values?.isDirectory != true, let size = values?.fileSize {
                    total += Int64(size)
                }
            }
        }
        return total
    }

    private func bookFolders() -> [(url: URL, size: Int64, accessed: Date)] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: paths.baseDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return contents.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.contentAccessDateKey, .isDirectoryKey])
            guard values?.isDirectory == true else { return nil }
            return (url, directorySize(url), values?.contentAccessDate ?? .distantPast)
        }
    }
}

public enum ContentCacheError: LocalizedError {
    case missingText
    case badStatus(Int)

    public var errorDescription: String? {
        switch self {
        case .missingText:
            return "Could not download book text from Project Gutenberg."
        case .badStatus(let code):
            return "Gutenberg request failed (\(code))."
        }
    }
}
