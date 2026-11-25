import Foundation

/// AniList GraphQL manga catalog: covers, genres, scores, chapter/volume counts, synopses.
/// Does not host page images — pair with MangaDex / MangaHook for reading.
public actor AniListMangaService {
    public static let shared = AniListMangaService()
    private let endpoint = URL(string: "https://graphql.anilist.co")!

    public func popular(limit: Int = 50, page: Int = 1, genre: String? = nil, format: String = "All") async throws -> [MangaSeries] {
        try await query(search: nil, sort: "POPULARITY_DESC", limit: limit, page: page, genre: genre, format: format)
    }

    public func trending(limit: Int = 50, page: Int = 1, genre: String? = nil, format: String = "All") async throws -> [MangaSeries] {
        try await query(search: nil, sort: "TRENDING_DESC", limit: limit, page: page, genre: genre, format: format)
    }

    public func search(_ term: String, limit: Int = 50, page: Int = 1, genre: String? = nil, format: String = "All") async throws -> [MangaSeries] {
        let q = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return try await popular(limit: limit, page: page, genre: genre, format: format) }
        return try await query(search: q, sort: "SEARCH_MATCH", limit: limit, page: page, genre: genre, format: format)
    }

    public func enrich(title: String) async -> MangaSeries? {
        (try? await search(title, limit: 1))?.first
    }

    public struct CharacterCredit: Identifiable, Hashable, Sendable {
        public var id: String { "\(name)-\(role)" }
        public let name: String
        public let role: String
        public let imageURL: String?
        public let voiceActor: String?
    }

    /// Characters for a manga title from AniList (not a hardcoded cast list).
    public func characters(forTitle title: String, limit: Int = 12) async -> [CharacterCredit] {
        let escaped = title.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let gql = """
        query {
          Page(perPage: 1) {
            media(type: MANGA, search: "\(escaped)", sort: SEARCH_MATCH) {
              characters(sort: ROLE, perPage: \(limit)) {
                edges {
                  role
                  node { name { full } image { large } }
                  voiceActors(language: JAPANESE, sort: RELEVANCE) { name { full } }
                }
              }
            }
          }
        }
        """
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["query": gql])
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let media = ((root["data"] as? [String: Any])?["Page"] as? [String: Any])?["media"] as? [[String: Any]],
              let edges = ((media.first?["characters"] as? [String: Any])?["edges"] as? [[String: Any]]) else { return [] }
        return edges.compactMap { edge in
            guard let node = edge["node"] as? [String: Any],
                  let name = (node["name"] as? [String: Any])?["full"] as? String else { return nil }
            let role = (edge["role"] as? String)?.replacingOccurrences(of: "_", with: " ") ?? "Character"
            let image = (node["image"] as? [String: Any])?["large"] as? String
            let va = ((edge["voiceActors"] as? [[String: Any]])?.first?["name"] as? [String: Any])?["full"] as? String
            return CharacterCredit(name: name, role: role.capitalized, imageURL: image, voiceActor: va)
        }
    }

    private func query(search: String?, sort: String, limit: Int, page: Int = 1, genre: String? = nil, format: String = "All") async throws -> [MangaSeries] {
        var mediaArgs = "type: MANGA, sort: \(sort)"
        if let search {
            let escaped = search.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            mediaArgs += ", search: \"\(escaped)\""
        }
        if let genre, !genre.isEmpty, genre != "All" {
            let escaped = genre.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            mediaArgs += ", genre: \"\(escaped)\""
        }
        // AniList countryOfOrigin: JP manga, KR manhwa, CN manhua
        switch format {
        case "Manga": mediaArgs += ", countryOfOrigin: JP"
        case "Manhwa": mediaArgs += ", countryOfOrigin: KR"
        case "Manhua": mediaArgs += ", countryOfOrigin: CN"
        default: break
        }
        let gql = """
        query {
          Page(page: \(max(1, page)), perPage: \(limit)) {
            media(\(mediaArgs)) {
              id
              title { romaji english native }
              description(asHtml: false)
              status
              chapters
              volumes
              genres
              averageScore
              favourites
              startDate { year }
              coverImage { large }
              staff(sort: RELEVANCE, perPage: 4) {
                edges { role node { name { full } } }
              }
            }
          }
        }
        """
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("AudioBy/1.0", forHTTPHeaderField: "User-Agent")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["query": gql])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let page = (root["data"] as? [String: Any])?["Page"] as? [String: Any],
              let media = page["media"] as? [[String: Any]] else { return [] }
        return media.compactMap(Self.map)
    }

    private static func map(_ row: [String: Any]) -> MangaSeries? {
        guard let id = row["id"] as? Int else { return nil }
        let titles = row["title"] as? [String: Any] ?? [:]
        let english = titles["english"] as? String
        let romaji = titles["romaji"] as? String
        let native = titles["native"] as? String
        let title = (english?.isEmpty == false ? english : nil) ?? romaji ?? native ?? "Untitled"
        let cover = (row["coverImage"] as? [String: Any])?["large"] as? String
        let genres = row["genres"] as? [String]
        let score = row["averageScore"] as? Int
        let chapters = row["chapters"] as? Int
        let year = (row["startDate"] as? [String: Any])?["year"] as? Int
        let status = (row["status"] as? String)?.replacingOccurrences(of: "_", with: " ")
        let favs = row["favourites"] as? Int
        var author = "AniList"
        if let edges = (row["staff"] as? [String: Any])?["edges"] as? [[String: Any]] {
            let story = edges.first {
                (($0["role"] as? String) ?? "").localizedCaseInsensitiveContains("story")
            } ?? edges.first
            if let name = ((story?["node"] as? [String: Any])?["name"] as? [String: Any])?["full"] as? String {
                author = name
            }
        }
        let synopsis = (row["description"] as? String)?
            .replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return MangaSeries(
            id: "anilist-\(id)",
            title: title,
            author: author,
            coverURL: cover,
            isLocal: false,
            source: .anilist,
            status: status,
            rating: score.map { Double($0) / 20.0 }, // 0...100 → ~0...5
            reviewsCount: favs.map { "\($0.formatted(.number.notation(.compactName))) favorites" },
            japaneseTitle: native,
            storyArtist: author,
            genres: genres,
            releaseYear: year.map { "\($0)" },
            publisher: "AniList",
            totalChapters: chapters,
            synopsis: synopsis
        )
    }
}
