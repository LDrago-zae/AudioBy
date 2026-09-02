import Foundation
import GRDB

public final class CatalogStore: @unchecked Sendable {
    public static let shared = CatalogStore()

    private let fileManager = FileManager.default
    private let etagKey = "AudioBy.CatalogSQLiteETag"
    private let lastModifiedKey = "AudioBy.CatalogSQLiteLastModified"
    private let session: URLSession

    public private(set) var dbQueue: DatabaseQueue?
    public private(set) var lastError: String?

    private var catalogDirectory: URL {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Catalog", isDirectory: true)
    }

    public var localCatalogURL: URL {
        catalogDirectory.appendingPathComponent("catalog.sqlite")
    }

    public var remoteCatalogURL: URL? {
        let env = ProcessInfo.processInfo.environment["CATALOG_SQLITE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !env.isEmpty, let url = URL(string: env) { return url }
        let plist = (Bundle.main.object(forInfoDictionaryKey: "CATALOG_SQLITE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !plist.isEmpty, !plist.hasPrefix("$("), let url = URL(string: plist) else { return nil }
        return url
    }

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func prepare() async {
        do {
            try fileManager.createDirectory(at: catalogDirectory, withIntermediateDirectories: true)
            if !fileManager.fileExists(atPath: localCatalogURL.path) {
                try installBundledCatalog()
            }
            try openDatabase()
            await refreshFromRemoteIfNeeded()
        } catch {
            lastError = error.localizedDescription
        }
    }

    public func openDatabase(at url: URL) throws {
        var config = Configuration()
        config.readonly = true
        dbQueue = try DatabaseQueue(path: url.path, configuration: config)
    }

    private func openDatabase() throws {
        try openDatabase(at: localCatalogURL)
    }

    private func bundledCatalogURL() -> URL? {
        Bundle.main.url(forResource: "catalog.fixture", withExtension: "sqlite")
            ?? Bundle.main.url(forResource: "catalog", withExtension: "sqlite")
    }

    private func installBundledCatalog() throws {
        guard let bundled = bundledCatalogURL() else {
            throw CatalogStoreError.missingBundledCatalog
        }
        if fileManager.fileExists(atPath: localCatalogURL.path) {
            try fileManager.removeItem(at: localCatalogURL)
        }
        try fileManager.copyItem(at: bundled, to: localCatalogURL)
    }

    public func refreshFromRemoteIfNeeded() async {
        guard let remote = remoteCatalogURL else { return }
        var request = URLRequest(url: remote)
        request.httpMethod = "GET"
        if let etag = UserDefaults.standard.string(forKey: etagKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        if let modified = UserDefaults.standard.string(forKey: lastModifiedKey) {
            request.setValue(modified, forHTTPHeaderField: "If-Modified-Since")
        }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            if http.statusCode == 304 { return }
            guard (200..<300).contains(http.statusCode), data.count > 100 else { return }
            let temp = catalogDirectory.appendingPathComponent("catalog.download.sqlite")
            try data.write(to: temp, options: .atomic)
            dbQueue = nil
            if fileManager.fileExists(atPath: localCatalogURL.path) {
                try fileManager.removeItem(at: localCatalogURL)
            }
            try fileManager.moveItem(at: temp, to: localCatalogURL)
            if let etag = http.value(forHTTPHeaderField: "ETag") {
                UserDefaults.standard.set(etag, forKey: etagKey)
            }
            if let modified = http.value(forHTTPHeaderField: "Last-Modified") {
                UserDefaults.standard.set(modified, forKey: lastModifiedKey)
            }
            try openDatabase()
        } catch {
            lastError = error.localizedDescription
            if dbQueue == nil {
                try? openDatabase()
            }
        }
    }
}

public enum CatalogStoreError: LocalizedError {
    case missingBundledCatalog
    case databaseNotOpen

    public var errorDescription: String? {
        switch self {
        case .missingBundledCatalog:
            return "The local catalog file is missing from the app bundle."
        case .databaseNotOpen:
            return "The local catalog is not ready yet."
        }
    }
}
