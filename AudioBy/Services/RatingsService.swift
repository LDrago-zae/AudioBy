import Foundation

public struct ExternalRatings: Sendable {
    public var average: Double      // 0...5
    public var count: Int
    public var reviews: [BookReview]
    public static let none = ExternalRatings(average: 0, count: 0, reviews: [])
}

/// Pulls real ratings and reviews from the original sources:
/// Internet Archive (audiobook reviews), Open Library (novel ratings), MangaDex (manga rating + follows).
public actor RatingsService {
    public static let shared = RatingsService()
    private var cache: [String: ExternalRatings] = [:]

    private func json(_ url: URL?) async -> [String: Any]? {
        guard let url, let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    // MARK: Audiobooks / novels

    public func ratings(for book: Audiobook) async -> ExternalRatings {
        if let hit = cache[book.id] { return hit }
        var result = ExternalRatings.none
        if let id = book.archiveIdentifier, let root = await json(URL(string: "https://archive.org/metadata/\(id)")) {
            let rows = root["reviews"] as? [[String: Any]] ?? []
            let reviews: [BookReview] = rows.compactMap { r in
                let body = (r["reviewbody"] as? String) ?? ""
                guard !body.isEmpty else { return nil }
                let stars = Double((r["stars"] as? String) ?? "") ?? (r["stars"] as? Double) ?? 5
                let title = (r["reviewtitle"] as? String) ?? ""
                return BookReview(
                    userName: (r["reviewer"] as? String) ?? "Listener",
                    rating: stars,
                    comment: title.isEmpty ? body : "\(title). \(body)",
                    dateString: String(((r["reviewdate"] as? String) ?? "").prefix(10)),
                    helpfulCount: 0
                )
            }
            if !reviews.isEmpty {
                result = ExternalRatings(average: reviews.map(\.rating).reduce(0, +) / Double(reviews.count),
                                         count: reviews.count, reviews: reviews)
            }
        }
        if result.count == 0 {
            var comps = URLComponents(string: "https://openlibrary.org/search.json")
            comps?.queryItems = [
                .init(name: "title", value: book.title),
                .init(name: "author", value: book.author),
                .init(name: "fields", value: "ratings_average,ratings_count"),
                .init(name: "limit", value: "1")
            ]
            if let root = await json(comps?.url),
               let doc = (root["docs"] as? [[String: Any]])?.first,
               let avg = doc["ratings_average"] as? Double {
                result = ExternalRatings(average: avg, count: (doc["ratings_count"] as? Int) ?? 0, reviews: [])
            }
        }
        cache[book.id] = result
        return result
    }

    // MARK: Manga

    /// Returns rating on a 0...5 scale (MangaDex is 0...10) and the follower count as `count`.
    public func ratings(for series: MangaSeries) async -> ExternalRatings {
        if let hit = cache[series.id] { return hit }
        var mangaId = UUID(uuidString: series.id) != nil ? series.id : nil
        if mangaId == nil, let match = try? await MangaDexService.shared.fetchManga(title: series.title) {
            mangaId = match.first { UUID(uuidString: $0.id) != nil }?.id
        }
        var result = ExternalRatings.none
        if let mangaId, let root = await json(URL(string: "https://api.mangadex.org/statistics/manga/\(mangaId)")),
           let stats = (root["statistics"] as? [String: Any])?[mangaId] as? [String: Any] {
            let rating = (stats["rating"] as? [String: Any])
            let avg = (rating?["bayesian"] as? Double) ?? (rating?["average"] as? Double) ?? 0
            result = ExternalRatings(average: avg / 2, count: (stats["follows"] as? Int) ?? 0, reviews: [])
        }
        cache[series.id] = result
        return result
    }
}
