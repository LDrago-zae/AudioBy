import SwiftUI
import UIKit
import CryptoKit

/// Memory + disk image cache. Images are downloaded once, then served locally (works offline).
public final class ImageCache: @unchecked Sendable {
    public static let shared = ImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let directory: URL
    private let session: URLSession
    private var inflight: [String: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()
    private let maxDiskBytes = 300 * 1024 * 1024

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        memory.countLimit = 300
        memory.totalCostLimit = 120 * 1024 * 1024
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
        Task.detached(priority: .background) { [weak self] in self?.trimDiskIfNeeded() }
    }

    private func key(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func fileURL(_ key: String) -> URL { directory.appendingPathComponent(key) }

    /// Instant lookup (memory, then disk) without hitting the network.
    public func cached(_ url: URL) -> UIImage? {
        let k = key(for: url)
        if let image = memory.object(forKey: k as NSString) { return image }
        if url.isFileURL { return UIImage(contentsOfFile: url.path) }
        let file = fileURL(k)
        guard let data = try? Data(contentsOf: file), let image = UIImage(data: data) else { return nil }
        memory.setObject(image, forKey: k as NSString, cost: data.count)
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
        return image
    }

    public func image(for url: URL) async -> UIImage? {
        if let hit = cached(url) { return hit }
        let k = key(for: url)

        lock.lock()
        if let existing = inflight[k] {
            lock.unlock()
            return await existing.value
        }
        let task = Task<UIImage?, Never> { [session] in
            guard let (data, response) = try? await session.data(from: url),
                  (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true,
                  let image = UIImage(data: data) else { return nil }
            self.memory.setObject(image, forKey: k as NSString, cost: data.count)
            try? data.write(to: self.fileURL(k), options: .atomic)
            return image
        }
        inflight[k] = task
        lock.unlock()

        let result = await task.value
        lock.lock(); inflight[k] = nil; lock.unlock()
        return result
    }

    public func prefetch(_ urls: [URL]) {
        for url in urls where !url.isFileURL {
            Task.detached(priority: .utility) { _ = await ImageCache.shared.image(for: url) }
        }
    }

    public func clear() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Trim oldest files when the disk cache grows past the limit.
    public func trimDiskIfNeeded() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }
        var entries = files.compactMap { url -> (URL, Date, Int)? in
            let v = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            return (url, v?.contentModificationDate ?? .distantPast, v?.fileSize ?? 0)
        }
        var total = entries.reduce(0) { $0 + $1.2 }
        guard total > maxDiskBytes else { return }
        entries.sort { $0.1 < $1.1 }
        for entry in entries where total > maxDiskBytes * 3 / 4 {
            try? fm.removeItem(at: entry.0)
            total -= entry.2
        }
    }
}

private struct ImageLoadFailure: Error {}

/// Drop-in replacement for `AsyncImage` that persists images after the first load.
public struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty

    public init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        if let url, let hit = ImageCache.shared.cached(url) {
            _phase = State(initialValue: .success(Image(uiImage: hit)))
        }
    }

    public init<I: View, P: View>(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P> {
        self.init(url: url) { phase in
            if let image = phase.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }

    public var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    @MainActor
    private func load() async {
        guard let url else { phase = .failure(ImageLoadFailure()); return }
        if case .success = phase, let hit = ImageCache.shared.cached(url) {
            phase = .success(Image(uiImage: hit))
            return
        }
        if let image = await ImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: image))
        } else if !Task.isCancelled {
            phase = .failure(ImageLoadFailure())
        }
    }
}
