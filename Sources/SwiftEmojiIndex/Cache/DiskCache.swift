import Foundation

/// Disk-based cache with an in-memory layer for emoji data.
///
/// Cache files are stored in the app's cache directory at:
/// `~/Library/Caches/[bundleID]/SwiftEmojiIndex/[sourceId].json`
///
/// The cache uses file modification dates to track when data was last updated.
public actor DiskCache: EmojiCache {
    /// Shared instance with default configuration.
    public static let shared = DiskCache()

    /// In-memory cache layer for fast access.
    private var memoryCache: [String: (entries: [EmojiRawEntry], lastUpdated: Date)] = [:]

    /// The base directory for cache files.
    private let cacheDirectory: URL

    /// Creates a new disk cache with the default cache directory.
    public init() {
        let baseDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "SwiftEmoji"
        self.cacheDirectory = baseDir
            .appendingPathComponent(bundleId)
            .appendingPathComponent("SwiftEmojiIndex")
    }

    /// Creates a new disk cache with a custom cache directory.
    ///
    /// - Parameter cacheDirectory: The directory to store cache files
    public init(cacheDirectory: URL) {
        self.cacheDirectory = cacheDirectory
    }

    /// Returns the cache file URL for a given source identifier.
    private func cacheFileURL(for sourceIdentifier: String) -> URL {
        cacheDirectory.appendingPathComponent("\(sourceIdentifier).json")
    }

    /// Ensures the cache directory exists.
    private func ensureCacheDirectoryExists() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - EmojiCache

    public func load(for sourceIdentifier: String) async throws -> (entries: [EmojiRawEntry], lastUpdated: Date)? {
        // Check memory cache first
        if let cached = memoryCache[sourceIdentifier] {
            return cached
        }

        let fileURL = cacheFileURL(for: sourceIdentifier)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data: Data
        let attributes: [FileAttributeKey: Any]

        do {
            data = try Data(contentsOf: fileURL)
            attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        } catch {
            throw EmojiIndexError.cacheReadFailed(underlying: error)
        }

        let entries: [EmojiRawEntry]
        do {
            entries = try JSONDecoder().decode([EmojiRawEntry].self, from: data)
        } catch {
            throw EmojiIndexError.decodingFailed(underlying: error)
        }

        let lastUpdated = (attributes[.modificationDate] as? Date) ?? Date.distantPast

        // Update memory cache
        memoryCache[sourceIdentifier] = (entries, lastUpdated)

        return (entries, lastUpdated)
    }

    public func save(_ entries: [EmojiRawEntry], for sourceIdentifier: String) async throws {
        do {
            try ensureCacheDirectoryExists()
        } catch {
            throw EmojiIndexError.cacheWriteFailed(underlying: error)
        }

        let fileURL = cacheFileURL(for: sourceIdentifier)

        let data: Data
        do {
            data = try JSONEncoder().encode(entries)
        } catch {
            throw EmojiIndexError.cacheWriteFailed(underlying: error)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw EmojiIndexError.cacheWriteFailed(underlying: error)
        }

        // Update memory cache
        memoryCache[sourceIdentifier] = (entries, Date())
    }

    public func clear(for sourceIdentifier: String) async throws {
        // Clear memory cache
        memoryCache.removeValue(forKey: sourceIdentifier)

        let fileURL = cacheFileURL(for: sourceIdentifier)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw EmojiIndexError.cacheWriteFailed(underlying: error)
        }
    }

    public func clearAll() async throws {
        // Clear memory cache
        memoryCache.removeAll()

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: cacheDirectory.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: cacheDirectory)
        } catch {
            throw EmojiIndexError.cacheWriteFailed(underlying: error)
        }
    }
}
