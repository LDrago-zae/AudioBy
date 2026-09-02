import Foundation
import PDFKit

public final class UserImportService: @unchecked Sendable {
    public static let shared = UserImportService()

    private let booksKey = "AudioBy.ImportedPDFBooks"
    private let fileManager = FileManager.default

    private var importsDirectory: URL {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("ImportedPDFs", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public func loadImportedBooks() -> [Audiobook] {
        guard let data = UserDefaults.standard.data(forKey: booksKey),
              let books = try? JSONDecoder().decode([Audiobook].self, from: data) else {
            return []
        }
        return books
    }

    public func saveImportedBooks(_ books: [Audiobook]) {
        if let data = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(data, forKey: booksKey)
        }
    }

    public func deleteStoredPDF(bookId: String) {
        let dir = importsDirectory.appendingPathComponent(bookId, isDirectory: true)
        try? fileManager.removeItem(at: dir)
    }

    public func importPDF(from url: URL) throws -> Audiobook {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        guard let document = PDFDocument(url: url) else {
            throw ImportError.unreadablePDF
        }

        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { continue }
            pages.append(text)
        }

        let fullText = pages.joined(separator: "\n\n")
        guard fullText.count > 80 else {
            throw ImportError.noSelectableText
        }

        let chapters = splitIntoChapters(fullText)
        let bookId = "pdf-\(UUID().uuidString)"
        let destDir = importsDirectory.appendingPathComponent(bookId, isDirectory: true)
        try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
        let destPDF = destDir.appendingPathComponent("source.pdf")
        if fileManager.fileExists(atPath: destPDF.path) {
            try fileManager.removeItem(at: destPDF)
        }
        try fileManager.copyItem(at: url, to: destPDF)

        let textDir = BookCachePaths.default.bookDirectory(forKey: bookId)
        try? fileManager.createDirectory(at: textDir, withIntermediateDirectories: true)
        try? fullText.write(to: BookCachePaths.default.textFileURL(forKey: bookId), atomically: true, encoding: .utf8)

        let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        let displayTitle = (title?.isEmpty == false ? title! : url.deletingPathExtension().lastPathComponent)

        return Audiobook(
            id: bookId,
            title: displayTitle,
            author: (author?.isEmpty == false ? author! : "Imported PDF"),
            narrator: "On-device voice",
            summary: "Imported PDF. Listen with on-device narration. You confirmed you have the right to use this file.",
            coverGradientColors: ["#0d150f", "#10c76b"],
            category: .fiction,
            chapters: chapters.map { $0.ensuringTranscript() },
            catalogSource: CatalogSourceKind.userPDF.rawValue,
            estimatedDuration: chapters.reduce(0) { $0 + $1.duration }
        )
    }

    public func splitIntoChapters(_ text: String, wordsPerChapter: Int = 1500) -> [Chapter] {
        let words = text.split { $0.isWhitespace || $0.isNewline }.map(String.init)
        guard !words.isEmpty else { return [] }

        let chunkCount = max(1, Int(ceil(Double(words.count) / Double(wordsPerChapter))))
        var chapters: [Chapter] = []
        for index in 0..<chunkCount {
            let start = index * wordsPerChapter
            let end = min(words.count, start + wordsPerChapter)
            let chunk = words[start..<end].joined(separator: " ")
            let duration = max(60, Double(end - start) / 150.0 * 60.0)
            chapters.append(
                Chapter(
                    id: "pdf-ch-\(index + 1)",
                    title: String(format: "Section %02d", index + 1),
                    chapterNumber: index + 1,
                    startTime: 0,
                    duration: duration,
                    fullText: chunk
                )
            )
        }
        return chapters
    }

    public enum ImportError: LocalizedError {
        case unreadablePDF
        case noSelectableText

        public var errorDescription: String? {
            switch self {
            case .unreadablePDF:
                return "This file could not be opened as a PDF."
            case .noSelectableText:
                return "This PDF has no selectable text. Scanned image-only files cannot be narrated."
            }
        }
    }
}
