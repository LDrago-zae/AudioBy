import Foundation
import GRDB

public struct CatalogBook: Codable, FetchableRecord, TableRecord, Sendable, Hashable {
    public static let databaseTableName = "books"

    public var id: Int64
    public var gutenbergId: Int?
    public var title: String
    public var author: String?
    public var language: String?
    public var subjects: String?
    public var coverUrl: String?
    public var hasLibrivox: Int
    public var metadataOnly: Int

    enum CodingKeys: String, CodingKey {
        case id
        case gutenbergId = "gutenberg_id"
        case title, author, language, subjects
        case coverUrl = "cover_url"
        case hasLibrivox = "has_librivox"
        case metadataOnly = "metadata_only"
    }

    public var isMetadataOnly: Bool { metadataOnly != 0 }
    public var hasLibriVoxAudio: Bool { hasLibrivox != 0 }

    public var audiobookId: String {
        if let gutenbergId, gutenbergId > 0 {
            return "gutenberg-\(gutenbergId)"
        }
        return "catalog-\(id)"
    }

    public func asAudiobook() -> Audiobook {
        let source: String
        if isMetadataOnly {
            source = "Open Library"
        } else if hasLibriVoxAudio {
            source = CatalogSourceKind.librivox.rawValue
        } else {
            source = CatalogSourceKind.gutenberg.rawValue
        }
        return Audiobook(
            id: audiobookId,
            title: title,
            author: author ?? "Unknown",
            narrator: hasLibriVoxAudio ? "LibriVox volunteers" : "On-device voice",
            summary: subjects ?? "",
            coverGradientColors: ["#0d150f", "#10c76b"],
            coverImageURL: coverUrl.flatMap(URL.init(string:)),
            category: AudiobookAPIService.categoryFromSubjects(subjects ?? ""),
            gutenbergId: gutenbergId,
            catalogSource: source
        )
    }
}
