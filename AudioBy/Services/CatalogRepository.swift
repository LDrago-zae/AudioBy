import Foundation
import GRDB

public final class CatalogRepository: @unchecked Sendable {
    public static let shared = CatalogRepository()

    private let store: CatalogStore

    public init(store: CatalogStore = .shared) {
        self.store = store
    }

    public func page(
        query: String?,
        category: AudiobookCategory,
        language: String = "en",
        limit: Int,
        offset: Int
    ) throws -> [Audiobook] {
        guard let dbQueue = store.dbQueue else {
            throw CatalogStoreError.databaseNotOpen
        }
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rows: [CatalogBook] = try dbQueue.read { db in
            if trimmed.isEmpty {
                return try browse(db, category: category, language: language, limit: limit, offset: offset)
            }
            return try search(db, query: trimmed, category: category, language: language, limit: limit, offset: offset)
        }
        return rows.filter { !$0.isMetadataOnly }.map { $0.asAudiobook() }
    }

    private func browse(
        _ db: Database,
        category: AudiobookCategory,
        language: String,
        limit: Int,
        offset: Int
    ) throws -> [CatalogBook] {
        let lang = "\(language)%"
        var request = CatalogBook
            .filter(sql: "metadata_only = 0 AND (language IS NULL OR language LIKE ?)", arguments: [lang])
        if let likes = Self.subjectLikes(for: category) {
            let clause = likes.map { _ in "lower(ifnull(subjects, '')) LIKE ?" }.joined(separator: " OR ")
            request = request.filter(sql: "(\(clause))", arguments: StatementArguments(likes))
        }
        return try request
            .order(sql: "title COLLATE NOCASE")
            .limit(limit, offset: offset)
            .fetchAll(db)
    }

    private func search(
        _ db: Database,
        query: String,
        category: AudiobookCategory,
        language: String,
        limit: Int,
        offset: Int
    ) throws -> [CatalogBook] {
        let match = Self.ftsMatch(from: query)
        guard !match.isEmpty else {
            return try browse(db, category: category, language: language, limit: limit, offset: offset)
        }
        let lang = "\(language)%"
        var sql = """
        SELECT books.* FROM books
        JOIN books_fts ON books_fts.rowid = books.id
        WHERE books.metadata_only = 0
          AND (books.language IS NULL OR books.language LIKE ?)
          AND books_fts MATCH ?
        """
        var arguments = StatementArguments([lang, match])
        if let likes = Self.subjectLikes(for: category) {
            sql += " AND (" + likes.map { _ in "lower(ifnull(books.subjects, '')) LIKE ?" }.joined(separator: " OR ") + ")"
            for like in likes {
                arguments += [like]
            }
        }
        sql += " ORDER BY rank LIMIT ? OFFSET ?"
        arguments += [limit, offset]
        return try CatalogBook.fetchAll(db, sql: sql, arguments: arguments)
    }

    public static func ftsMatch(from raw: String) -> String {
        let tokens = raw.split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 2 }
        guard !tokens.isEmpty else { return "" }
        return tokens.map { token in
            let escaped = token.replacingOccurrences(of: "\"", with: "")
            return "\"\(escaped)\"*"
        }.joined(separator: " AND ")
    }

    public static func subjectLikes(for category: AudiobookCategory) -> [String]? {
        switch category {
        case .all:
            return nil
        case .technology:
            return ["%science%", "%technolog%", "%astronom%", "%mathematic%"]
        case .business:
            return ["%econom%", "%business%", "%politic%", "%commerce%"]
        case .fiction:
            return ["%fiction%", "%romance%", "%fantasy%", "%mystery%", "%adventure%", "%horror%", "%children%"]
        case .philosophy:
            return ["%philosoph%", "%ethic%", "%religion%"]
        case .biography:
            return ["%biograph%", "%history%", "%memoir%"]
        }
    }
}
