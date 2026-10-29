import Foundation

public struct MangaSeries: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var author: String
    public var coverURL: String?
    public var isLocal: Bool

    public init(id: String, title: String, author: String, coverURL: String?, isLocal: Bool) {
        self.id = id
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.isLocal = isLocal
    }
}

public struct MangaChapter: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var numberLabel: String
    public var imagePaths: [String]

    public init(id: String, title: String, numberLabel: String, imagePaths: [String] = []) {
        self.id = id
        self.title = title
        self.numberLabel = numberLabel
        self.imagePaths = imagePaths
    }
}

public struct StoredManga: Identifiable, Codable, Hashable, Sendable {
    public var series: MangaSeries
    public var chapters: [MangaChapter]

    public var id: String { series.id }
}

public struct MangaProgress: Codable, Sendable {
    public var chapterId: String
    public var page: Int
    public var vertical: Bool
}
