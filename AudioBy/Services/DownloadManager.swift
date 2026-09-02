import Foundation
import Observation
import Network

public enum DownloadStatus: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(localURL: URL)
    case failed(error: String)
}

@Observable
public final class DownloadManager: NSObject, @unchecked Sendable {
    public static let shared = DownloadManager()

    public var downloadStatuses: [String: DownloadStatus] = [:]
    public var downloadedBookIds: Set<String> = []
    public var totalStorageUsedBytes: Int64 = 0

    @ObservationIgnored private var activeTasks: [String: URLSessionDownloadTask] = [:]
    @ObservationIgnored private var _urlSession: URLSession?
    @ObservationIgnored private let fileManager = FileManager.default
    @ObservationIgnored private let paths = BookCachePaths.default

    private var urlSession: URLSession {
        if let session = _urlSession { return session }
        let config = URLSessionConfiguration.background(withIdentifier: "com.audioby.downloadmanager")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        _urlSession = session
        return session
    }

    public override init() {
        super.init()
        scanDownloadedFiles()
    }

    private var legacyAudiobooksDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Audiobooks", isDirectory: true)
    }

    private func cacheKey(for book: Audiobook) -> String {
        BookCachePaths.cacheKey(for: book)
    }

    public func downloadAudiobook(_ book: Audiobook) {
        guard !downloadedBookIds.contains(book.id) else { return }

        if !EntitlementService.shared.canDownloadMore {
            downloadStatuses[book.id] = .failed(error: "Free accounts can download 1 title. Upgrade to Plus for unlimited offline listening.")
            return
        }

        downloadStatuses[book.id] = .downloading(progress: 0.05)

        Task {
            do {
                try await assertWifiAllowedIfRequired()
            } catch {
                await MainActor.run {
                    self.downloadStatuses[book.id] = .failed(error: error.localizedDescription)
                }
                return
            }

            var source = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? book
            if source.chapters.isEmpty {
                _ = await AudiobookRepository.shared.loadLiveChapters(for: source.id)
                source = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? source
            }

            let key = cacheKey(for: source)
            let audioDir = paths.audioDirectory(forKey: key)
            try? fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)

            var successCount = 0
            let downloadable = source.chapters.filter { $0.remoteAudioURL != nil }

            if downloadable.isEmpty {
                if let gid = source.gutenbergId ?? Int(key), gid > 0 {
                    do {
                        _ = try await ContentCache.shared.fetchText(for: gid)
                        successCount = 1
                    } catch {
                        await MainActor.run {
                            self.downloadStatuses[source.id] = .failed(error: "No downloadable audio tracks for this title.")
                        }
                        return
                    }
                } else {
                    await MainActor.run {
                        self.downloadStatuses[source.id] = .failed(error: "No downloadable audio tracks for this title.")
                    }
                    return
                }
            }

            let totalChapters = max(downloadable.count, 1)
            for (index, chapter) in downloadable.enumerated() {
                if let remoteURL = chapter.remoteAudioURL {
                    let destURL = paths.chapterAudioURL(forKey: key, chapterNumber: chapter.chapterNumber)
                    do {
                        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
                        if fileManager.fileExists(atPath: destURL.path) {
                            try? fileManager.removeItem(at: destURL)
                        }
                        try fileManager.moveItem(at: tempURL, to: destURL)
                        successCount += 1
                    } catch {
                        print("Chapter download failed: \(error)")
                    }
                }

                await MainActor.run {
                    let progress = Double(index + 1) / Double(totalChapters)
                    self.downloadStatuses[source.id] = .downloading(progress: progress)
                }
            }

            await ContentCache.shared.touch(key: key)
            await ContentCache.shared.evictIfNeeded()

            await MainActor.run {
                if successCount == 0 {
                    self.downloadStatuses[source.id] = .failed(error: "Download failed. Retry when you have a connection.")
                } else {
                    self.downloadedBookIds.insert(source.id)
                    self.downloadStatuses[source.id] = .downloaded(localURL: paths.bookDirectory(forKey: key))
                }
                self.scanDownloadedFiles()
            }
        }
    }

    public func isBookDownloaded(_ bookId: String) -> Bool {
        downloadedBookIds.contains(bookId)
    }

    public func localURLForChapter(bookId: String, chapterNumber: Int) -> URL? {
        let book = AudiobookRepository.shared.book(id: bookId)
        let key = BookCachePaths.cacheKey(bookId: bookId, gutenbergId: book?.gutenbergId)
        let cached = paths.chapterAudioURL(forKey: key, chapterNumber: chapterNumber)
        if fileManager.fileExists(atPath: cached.path) { return cached }
        let m4a = paths.chapterAudioM4AURL(forKey: key, chapterNumber: chapterNumber)
        if fileManager.fileExists(atPath: m4a.path) { return m4a }

        let legacyDir = legacyAudiobooksDirectoryURL.appendingPathComponent(bookId, isDirectory: true)
        let mp3URL = legacyDir.appendingPathComponent("chapter_\(chapterNumber).mp3")
        if fileManager.fileExists(atPath: mp3URL.path) { return mp3URL }
        let m4aURL = legacyDir.appendingPathComponent("chapter_\(chapterNumber).m4a")
        if fileManager.fileExists(atPath: m4aURL.path) { return m4aURL }
        return nil
    }

    public func deleteDownload(for bookId: String) {
        let book = AudiobookRepository.shared.book(id: bookId)
        let key = BookCachePaths.cacheKey(bookId: bookId, gutenbergId: book?.gutenbergId)
        try? fileManager.removeItem(at: paths.bookDirectory(forKey: key))
        try? fileManager.removeItem(at: legacyAudiobooksDirectoryURL.appendingPathComponent(bookId, isDirectory: true))
        downloadedBookIds.remove(bookId)
        downloadStatuses[bookId] = .notDownloaded
        scanDownloadedFiles()
    }

    public func clearAllCache() {
        try? fileManager.removeItem(at: paths.baseDirectory)
        try? fileManager.removeItem(at: legacyAudiobooksDirectoryURL)
        try? fileManager.createDirectory(at: paths.baseDirectory, withIntermediateDirectories: true)
        downloadedBookIds.removeAll()
        downloadStatuses.removeAll()
        scanDownloadedFiles()
    }

    public var formattedStorageUsed: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageUsedBytes)
    }

    public func scanDownloadedFiles() {
        var totalSize: Int64 = 0
        var foundIds: Set<String> = []

        func scan(root: URL, idFromFolder: (String) -> String) {
            guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else { return }
            for case let fileURL as URL in enumerator {
                let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if resourceValues?.isDirectory == true {
                    let name = fileURL.lastPathComponent
                    if name != root.lastPathComponent && name != "audio" {
                        foundIds.insert(idFromFolder(name))
                    }
                } else if let fileSize = resourceValues?.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        scan(root: paths.baseDirectory) { folder in
            if let gid = Int(folder) {
                return "gutenberg-\(gid)"
            }
            return folder
        }
        scan(root: legacyAudiobooksDirectoryURL) { $0 }

        totalStorageUsedBytes = totalSize
        downloadedBookIds = foundIds
    }

    private func assertWifiAllowedIfRequired() async throws {
        guard UserDefaults.standard.bool(forKey: "downloadWifiOnly") else { return }
        let path = await currentNetworkPath()
        if path.usesInterfaceType(.cellular) {
            throw DownloadRestrictionError.wifiOnly
        }
    }

    private func currentNetworkPath() async -> NWPath {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path)
            }
            monitor.start(queue: DispatchQueue.global(qos: .userInitiated))
        }
    }
}

public enum DownloadRestrictionError: LocalizedError {
    case wifiOnly

    public var errorDescription: String? {
        switch self {
        case .wifiOnly:
            return "Downloads are limited to Wi-Fi. Connect to Wi-Fi or turn off Wi-Fi only in Settings."
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    }
}
