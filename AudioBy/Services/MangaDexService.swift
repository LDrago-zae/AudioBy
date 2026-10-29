import Foundation

public enum MangaDexError: Error, LocalizedError {
    case badResponse
    case empty

    public var errorDescription: String? {
        switch self {
        case .badResponse: return "MangaDex did not return a catalog."
        case .empty: return "No chapters are available in English for this series."
        }
    }
}

public final class MangaDexService: Sendable {
    public static let shared = MangaDexService()
    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    public func popular() async throws -> [MangaSeries] {
        try await fetchManga(title: nil)
    }

    public func search(title: String) async throws -> [MangaSeries] {
        let query = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try await popular() }
        return try await fetchManga(title: query)
    }

    private func fetchManga(title: String?) async throws -> [MangaSeries] {
        var parts = URLComponents(string: "https://api.mangadex.org/manga")!
        var items = [
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "availableTranslatedLanguage[]", value: "en"),
            URLQueryItem(name: "includes[]", value: "cover_art"),
            URLQueryItem(name: "includes[]", value: "author"),
            URLQueryItem(name: "contentRating[]", value: "safe"),
            URLQueryItem(name: "contentRating[]", value: "suggestive"),
            URLQueryItem(name: "order[followedCount]", value: "desc")
        ]
        if let title, !title.isEmpty {
            items.append(URLQueryItem(name: "title", value: title))
        }
        parts.queryItems = items
        let json = try await get(parts.url!)
        let rows = json["data"] as? [[String: Any]] ?? []
        return rows.compactMap(Self.series(from:))
    }

    public func chapters(for seriesId: String) async throws -> [MangaChapter] {
        var collected: [[String: Any]] = []
        var offset = 0
        while offset < 300 {
            var parts = URLComponents(string: "https://api.mangadex.org/manga/\(seriesId)/feed")!
            parts.queryItems = [
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "translatedLanguage[]", value: "en"),
                URLQueryItem(name: "order[chapter]", value: "asc"),
                URLQueryItem(name: "contentRating[]", value: "safe"),
                URLQueryItem(name: "contentRating[]", value: "suggestive")
            ]
            let json = try await get(parts.url!)
            let rows = json["data"] as? [[String: Any]] ?? []
            collected.append(contentsOf: rows)
            let total = json["total"] as? Int ?? collected.count
            offset += rows.count
            if rows.isEmpty || offset >= total { break }
        }
        let chapters = collected.compactMap(Self.chapter(from:)).sorted {
            (Double($0.numberLabel) ?? 0) < (Double($1.numberLabel) ?? 0)
        }
        return chapters
    }

    public func pageURLs(chapterId: String) async throws -> [URL] {
        let json = try await get(URL(string: "https://api.mangadex.org/at-home/server/\(chapterId)")!)
        guard let base = json["baseUrl"] as? String,
              let chapter = json["chapter"] as? [String: Any],
              let hash = chapter["hash"] as? String else {
            throw MangaDexError.badResponse
        }
        let saver = chapter["dataSaver"] as? [String] ?? []
        let full = chapter["data"] as? [String] ?? []
        let names = saver.isEmpty ? full : saver
        let quality = saver.isEmpty ? "data" : "data-saver"
        guard !names.isEmpty else { throw MangaDexError.empty }
        return names.compactMap { name in
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
            return URL(string: "\(base)/\(quality)/\(hash)/\(encoded)")
        }
    }

    private func get(_ url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.setValue("AudioBy/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MangaDexError.badResponse
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MangaDexError.badResponse
        }
        return json
    }

    private static func series(from row: [String: Any]) -> MangaSeries? {
        guard let id = row["id"] as? String,
              let attributes = row["attributes"] as? [String: Any] else { return nil }
        let titles = attributes["title"] as? [String: String] ?? [:]
        let title = titles["en"] ?? titles.values.first ?? "Untitled"
        let relationships = row["relationships"] as? [[String: Any]] ?? []
        let author = relationships.first { $0["type"] as? String == "author" }
            .flatMap { ($0["attributes"] as? [String: Any])?["name"] as? String } ?? "MangaDex"
        let file = relationships.first { $0["type"] as? String == "cover_art" }
            .flatMap { ($0["attributes"] as? [String: Any])?["fileName"] as? String }
        let cover = file.map { "https://uploads.mangadex.org/covers/\(id)/\($0).256.jpg" }
        return MangaSeries(id: id, title: title, author: author, coverURL: cover, isLocal: false)
    }

    private static func chapter(from row: [String: Any]) -> MangaChapter? {
        guard let id = row["id"] as? String,
              let attributes = row["attributes"] as? [String: Any] else { return nil }
        let pageCount = attributes["pages"] as? Int ?? 0
        let external = (attributes["externalUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard pageCount > 0, external.isEmpty else { return nil }
        let number = attributes["chapter"] as? String ?? "?"
        let name = (attributes["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = name.isEmpty ? "Chapter \(number)" : "Chapter \(number) · \(name)"
        return MangaChapter(id: id, title: title, numberLabel: number)
    }
}
