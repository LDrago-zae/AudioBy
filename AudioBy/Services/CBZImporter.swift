import Foundation

enum CBZError: Error, LocalizedError {
    case unreadable
    case empty

    var errorDescription: String? {
        switch self {
        case .unreadable: return "That file is not a CBZ or ZIP of page images."
        case .empty: return "No page images were found in that file."
        }
    }
}

enum CBZImporter {
    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif"]

    static func importFile(at url: URL) throws -> StoredManga {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let entries = try unzipImages(data)
        guard !entries.isEmpty else { throw CBZError.empty }

        let id = UUID().uuidString
        let folder = libraryRoot().appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var paths: [String] = []
        for (index, entry) in entries.enumerated() {
            let ext = (entry.name as NSString).pathExtension.lowercased()
            let filename = String(format: "%04d.%@", index + 1, ext.isEmpty ? "jpg" : ext)
            let file = folder.appendingPathComponent(filename)
            try entry.data.write(to: file)
            paths.append(file.path)
        }
        let title = url.deletingPathExtension().lastPathComponent
        let series = MangaSeries(id: id, title: title, author: "Imported", coverURL: paths.first, isLocal: true)
        let chapter = MangaChapter(id: "\(id)-1", title: title, numberLabel: "1", imagePaths: paths)
        return StoredManga(series: series, chapters: [chapter])
    }

    private static func libraryRoot() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Manga", isDirectory: true)
    }

    private struct ZipImage {
        var name: String
        var data: Data
    }

    private static func unzipImages(_ data: Data) throws -> [ZipImage] {
        let bytes = [UInt8](data)
        guard let eocd = findEOCD(bytes) else { throw CBZError.unreadable }
        let count = intAt(bytes, eocd + 10, 2)
        let offset = intAt(bytes, eocd + 16, 4)
        var cursor = offset
        var images: [ZipImage] = []
        for _ in 0..<count {
            guard cursor + 46 <= bytes.count else { break }
            guard bytes[cursor] == 0x50, bytes[cursor + 1] == 0x4b, bytes[cursor + 2] == 0x01, bytes[cursor + 3] == 0x02 else { break }
            let method = intAt(bytes, cursor + 10, 2)
            let compressed = intAt(bytes, cursor + 20, 4)
            let uncompressed = intAt(bytes, cursor + 24, 4)
            let nameLength = intAt(bytes, cursor + 28, 2)
            let extraLength = intAt(bytes, cursor + 30, 2)
            let commentLength = intAt(bytes, cursor + 32, 2)
            let localOffset = intAt(bytes, cursor + 42, 4)
            let nameStart = cursor + 46
            let nameEnd = nameStart + nameLength
            guard nameEnd <= bytes.count else { break }
            let name = String(decoding: bytes[nameStart..<nameEnd], as: UTF8.self)
            cursor = nameEnd + extraLength + commentLength
            let ext = (name as NSString).pathExtension.lowercased()
            guard imageExtensions.contains(ext), !name.hasSuffix("/") else { continue }
            guard let payload = readLocal(bytes, offset: localOffset, method: method, compressed: compressed, uncompressed: uncompressed) else { continue }
            images.append(ZipImage(name: name, data: payload))
        }
        return images.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func readLocal(_ bytes: [UInt8], offset: Int, method: Int, compressed: Int, uncompressed: Int) -> Data? {
        guard offset + 30 <= bytes.count else { return nil }
        let nameLength = intAt(bytes, offset + 26, 2)
        let extraLength = intAt(bytes, offset + 28, 2)
        let start = offset + 30 + nameLength + extraLength
        let end = start + compressed
        guard end <= bytes.count else { return nil }
        let slice = Data(bytes[start..<end])
        if method == 0 { return slice }
        guard method == 8, uncompressed > 0 else { return nil }
        var output = Data(count: uncompressed)
        let written = output.withUnsafeMutableBytes { dst -> Int32 in
            slice.withUnsafeBytes { src -> Int32 in
                audioby_raw_inflate(
                    src.bindMemory(to: UInt8.self).baseAddress,
                    Int32(slice.count),
                    dst.bindMemory(to: UInt8.self).baseAddress,
                    Int32(uncompressed)
                )
            }
        }
        guard written == uncompressed else { return nil }
        return output
    }

    private static func findEOCD(_ bytes: [UInt8]) -> Int? {
        let start = max(0, bytes.count - 22 - 65535)
        var index = bytes.count - 22
        while index >= start {
            if bytes[index] == 0x50, bytes[index + 1] == 0x4b, bytes[index + 2] == 0x05, bytes[index + 3] == 0x06 {
                return index
            }
            index -= 1
        }
        return nil
    }

    private static func intAt(_ bytes: [UInt8], _ offset: Int, _ length: Int) -> Int {
        var value = 0
        for shift in 0..<length {
            value |= Int(bytes[offset + shift]) << (8 * shift)
        }
        return value
    }
}
