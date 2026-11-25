import Foundation

/// Client for the open-source MangaHook API (https://github.com/kiraaziz/mangahook-api).
/// Self-host with: `cd Tools/mangahook-api/server && npm install && npm start`
/// Default base URL is localhost:3000 (iOS Simulator). Override with UserDefaults key `AudioBy.MangaHookBaseURL`.
public actor MangaHookService {
    public static let shared = MangaHookService()

    public var baseURL: URL {
        if let raw = UserDefaults.standard.string(forKey: "AudioBy.MangaHookBaseURL"),
           let url = URL(string: raw), !raw.isEmpty {
            return url
        }
        return URL(string: "http://127.0.0.1:3000")!
    }

    private func get(_ path: String, query: [URLQueryItem] = []) async throws -> Any {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { comps.queryItems = query }
        guard let url = comps.url else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("AudioBy/1.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONSerialization.jsonObject(with: data)
    }

    public func popular(page: Int = 1) async throws -> [MangaSeries] {
        let json = try await get("api/mangaList", query: [
            .init(name: "page", value: "\(page)"),
            .init(name: "type", value: "latest"),
            .init(name: "category", value: "ALL"),
            .init(name: "state", value: "all")
        ])
        let rows = (json as? [String: Any])?["mangaList"] as? [[String: Any]] ?? []
        return rows.compactMap(Self.mapListItem)
    }

    public func search(_ term: String, page: Int = 1) async throws -> [MangaSeries] {
        let q = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return try await popular(page: page) }
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? q
        let json = try await get("api/search/\(encoded)", query: [.init(name: "page", value: "\(page)")])
        let rows = (json as? [String: Any])?["mangaList"] as? [[String: Any]] ?? []
        return rows.compactMap(Self.mapListItem)
    }

    public func detail(id: String) async throws -> (series: MangaSeries, chapters: [MangaChapter]) {
        let rawId = id.hasPrefix("hook-") ? String(id.dropFirst(5)) : id
        let json = try await get("api/manga/\(rawId)") as? [String: Any] ?? [:]
        let series = MangaSeries(
            id: "hook-\(rawId)",
            title: (json["name"] as? String) ?? rawId,
            author: (json["author"] as? String) ?? "Unknown",
            coverURL: json["imageUrl"] as? String,
            isLocal: false,
            source: .mangahook,
            status: json["status"] as? String,
            genres: json["genres"] as? [String],
            synopsis: nil
        )
        let chapters: [MangaChapter] = ((json["chapterList"] as? [[String: Any]]) ?? []).compactMap { row in
            guard let chId = row["id"] as? String else { return nil }
            let name = (row["name"] as? String) ?? chId
            let num = name.split(separator: " ").last.map(String.init) ?? name
            return MangaChapter(
                id: "hook-\(rawId)/\(chId)",
                title: name,
                numberLabel: num,
                pageCount: nil,
                releaseDate: row["createdAt"] as? String,
                scanGroup: "MangaHook"
            )
        }
        return (series, chapters)
    }

    public func pages(chapterId: String) async throws -> [URL] {
        // chapterId format: hook-{mangaId}/{chapterSlug} or mangaId/chapterSlug
        let trimmed = chapterId.hasPrefix("hook-") ? String(chapterId.dropFirst(5)) : chapterId
        let parts = trimmed.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return [] }
        let json = try await get("api/manga/\(parts[0])/\(parts[1])") as? [String: Any] ?? [:]
        let images = json["images"] as? [[String: Any]] ?? []
        return images.compactMap { ($0["image"] as? String).flatMap(URL.init(string:)) }
    }

    public func resolveId(forTitle title: String) async -> String? {
        let hits = try? await search(title, page: 1)
        return hits?.first?.id
    }

    private static func mapListItem(_ row: [String: Any]) -> MangaSeries? {
        guard let id = row["id"] as? String, let title = row["title"] as? String else { return nil }
        return MangaSeries(
            id: "hook-\(id)",
            title: title,
            author: "MangaHook",
            coverURL: row["image"] as? String,
            isLocal: false,
            source: .mangahook,
            status: nil,
            synopsis: row["description"] as? String,
            lastReadChapter: row["chapter"] as? String
        )
    }
}
