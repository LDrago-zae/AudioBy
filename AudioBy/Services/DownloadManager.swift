import Foundation
import Observation

public enum DownloadStatus: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(localURL: URL)
    case failed(error: String)
}

@Observable
public final class DownloadManager: NSObject, @unchecked Sendable {
    public static let shared = DownloadManager()

    public var downloadStatuses: [String: DownloadStatus] = [:] // Key: bookId or chapterId
    public var downloadedBookIds: Set<String> = []
    public var totalStorageUsedBytes: Int64 = 0

    @ObservationIgnored private var activeTasks: [String: URLSessionDownloadTask] = [:]
    @ObservationIgnored private var _urlSession: URLSession?
    @ObservationIgnored private let fileManager = FileManager.default

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
        createAudiobooksDirectoryIfNeeded()
        scanDownloadedFiles()
    }

    // MARK: - Directory Management

    private var audiobooksDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Audiobooks", isDirectory: true)
    }

    private func createAudiobooksDirectoryIfNeeded() {
        let url = audiobooksDirectoryURL
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    // MARK: - Download Operations

    public func downloadAudiobook(_ book: Audiobook) {
        guard !downloadedBookIds.contains(book.id) else { return }

        downloadStatuses[book.id] = .downloading(progress: 0.05)

        Task {
            var source = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? book
            if source.chapters.isEmpty {
                _ = await AudiobookRepository.shared.loadLiveChapters(for: source.id)
                source = AudiobookRepository.shared.audiobooks.first(where: { $0.id == book.id }) ?? source
            }

            let bookDir = audiobooksDirectoryURL.appendingPathComponent(source.id, isDirectory: true)
            try? fileManager.createDirectory(at: bookDir, withIntermediateDirectories: true)

            var successCount = 0
            let downloadable = source.chapters.filter { $0.remoteAudioURL != nil }
            let totalChapters = max(downloadable.count, 1)

            if downloadable.isEmpty {
                await MainActor.run {
                    self.downloadStatuses[source.id] = .failed(error: "No downloadable audio tracks for this title.")
                }
                return
            }

            for (index, chapter) in downloadable.enumerated() {
                if let remoteURL = chapter.remoteAudioURL {
                    let destURL = bookDir.appendingPathComponent("chapter_\(chapter.chapterNumber).mp3")
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

            await MainActor.run {
                if successCount == 0 {
                    self.downloadStatuses[source.id] = .failed(error: "Download failed. Retry when you have a connection.")
                } else {
                    self.downloadedBookIds.insert(source.id)
                    self.downloadStatuses[source.id] = .downloaded(localURL: bookDir)
                }
                self.scanDownloadedFiles()
            }
        }
    }

    public func isBookDownloaded(_ bookId: String) -> Bool {
        return downloadedBookIds.contains(bookId)
    }

    public func localURLForChapter(bookId: String, chapterNumber: Int) -> URL? {
        let bookDir = audiobooksDirectoryURL.appendingPathComponent(bookId, isDirectory: true)
        let mp3URL = bookDir.appendingPathComponent("chapter_\(chapterNumber).mp3")
        if fileManager.fileExists(atPath: mp3URL.path) {
            return mp3URL
        }
        let m4aURL = bookDir.appendingPathComponent("chapter_\(chapterNumber).m4a")
        if fileManager.fileExists(atPath: m4aURL.path) {
            return m4aURL
        }
        return nil
    }

    public func deleteDownload(for bookId: String) {
        let bookDir = audiobooksDirectoryURL.appendingPathComponent(bookId, isDirectory: true)
        try? fileManager.removeItem(at: bookDir)
        downloadedBookIds.remove(bookId)
        downloadStatuses[bookId] = .notDownloaded
        scanDownloadedFiles()
    }

    public func clearAllCache() {
        try? fileManager.removeItem(at: audiobooksDirectoryURL)
        createAudiobooksDirectoryIfNeeded()
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

    // MARK: - Scanning Disk

    public func scanDownloadedFiles() {
        var totalSize: Int64 = 0
        var foundIds: Set<String> = []

        if let enumerator = fileManager.enumerator(at: audiobooksDirectoryURL, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]) {
                    if resourceValues.isDirectory == true {
                        let id = fileURL.lastPathComponent
                        if id != "Audiobooks" {
                            foundIds.insert(id)
                        }
                    } else if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        }

        self.totalStorageUsedBytes = totalSize
        self.downloadedBookIds = foundIds
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled in individual task runners
    }
}
