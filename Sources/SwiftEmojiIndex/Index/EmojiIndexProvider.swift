import Foundation
import Observation

/// Default emoji index provider with caching and search.
///
/// This class manages emoji data from a data source, provides caching,
/// and implements efficient searching.
///
/// ## Usage
///
/// ```swift
/// // Use the shared instance with Gemoji data source
/// let index = EmojiIndexProvider.shared
///
/// // Load and search
/// try await index.load()
/// let results = await index.search("smile")
///
/// // Or create with a custom data source
/// let customIndex = EmojiIndexProvider(source: MyCustomDataSource())
/// ```
@Observable
public final class EmojiIndexProvider: EmojiIndex, @unchecked Sendable {
    /// Shared instance using the Gemoji data source.
    public static let shared = EmojiIndexProvider(source: GemojiDataSource.shared)

    // MARK: - Configuration

    private let source: any EmojiDataSource
    private let cache: any EmojiCache
    private let customFallbackURL: URL?

    // MARK: - State

    /// All loaded emojis.
    private var emojis: [Emoji] = []

    /// Emojis indexed by character for O(1) lookup.
    private var byCharacter: [String: Emoji] = [:]

    /// Emojis indexed by shortcode for O(1) lookup.
    private var byShortcode: [String: Emoji] = [:]

    /// Emojis organized by category.
    private var byCategory: [EmojiCategory: [Emoji]] = [:]

    /// The date when data was last updated.
    public private(set) var lastUpdated: Date?

    /// Whether the index has been loaded.
    public private(set) var isLoaded: Bool = false

    /// Lock for thread-safe access.
    private let lock = NSLock()

    // MARK: - Initialization

    /// Creates a new index provider with a specific data source.
    ///
    /// - Parameters:
    ///   - source: The data source to fetch emoji data from
    ///   - cache: The cache to use for storing data (default: DiskCache)
    ///   - fallbackURL: Optional custom fallback file URL. Must be a JSON file in `EmojiRawEntry` format.
    ///                  If nil, uses the bundled fallback. Run `swift run BuildEmojiIndex` to generate one.
    public init(
        source: any EmojiDataSource,
        cache: any EmojiCache = DiskCache.shared,
        fallbackURL: URL? = nil
    ) {
        self.source = source
        self.cache = cache
        self.customFallbackURL = fallbackURL
    }

    // MARK: - EmojiIndex

    public var allEmojis: [Emoji] {
        get async throws {
            try await ensureLoaded()
            return lock.withLock { emojis }
        }
    }

    public var categories: [EmojiCategory: [Emoji]] {
        get async throws {
            try await ensureLoaded()
            return lock.withLock { byCategory }
        }
    }

    public var isStale: Bool {
        get async {
            guard let lastUpdated = self.lastUpdated else {
                return true
            }
            return Date().timeIntervalSince(lastUpdated) > source.refreshInterval
        }
    }

    public func emoji(for character: String) async -> Emoji? {
        try? await ensureLoaded()
        return lock.withLock { byCharacter[character] }
    }

    public func emoji(forShortcode shortcode: String) async -> Emoji? {
        try? await ensureLoaded()
        let lowercased = shortcode.lowercased()
        return lock.withLock { byShortcode[lowercased] }
    }

    public func search(_ query: String) async -> [Emoji] {
        try? await ensureLoaded()

        let query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return lock.withLock { emojis }
        }

        return lock.withLock {
            var results: [Emoji] = []
            var seen = Set<String>()

            // Priority 1: Exact shortcode match
            if let exact = byShortcode[query] {
                results.append(exact)
                seen.insert(exact.character)
            }

            // Priority 2: Name contains query
            for emoji in emojis {
                guard !seen.contains(emoji.character) else { continue }
                if emoji.name.lowercased().contains(query) {
                    results.append(emoji)
                    seen.insert(emoji.character)
                }
            }

            // Priority 3: Shortcode prefix match
            for emoji in emojis {
                guard !seen.contains(emoji.character) else { continue }
                if emoji.shortcodes.contains(where: { $0.lowercased().hasPrefix(query) }) {
                    results.append(emoji)
                    seen.insert(emoji.character)
                }
            }

            // Priority 4: Keyword prefix match
            for emoji in emojis {
                guard !seen.contains(emoji.character) else { continue }
                if emoji.keywords.contains(where: { $0.lowercased().hasPrefix(query) }) {
                    results.append(emoji)
                    seen.insert(emoji.character)
                }
            }

            return results
        }
    }

    public func refresh() async throws {
        let entries = try await source.fetch()
        try await cache.save(entries, for: source.identifier)
        await loadFromEntries(entries)
    }

    // MARK: - Loading

    /// Ensures the index is loaded, loading from cache or source if needed.
    private func ensureLoaded() async throws {
        if lock.withLock({ isLoaded }) {
            return
        }

        // Try loading from cache first
        if let cached = try? await cache.load(for: source.identifier) {
            await loadFromEntries(cached.entries)
            lock.withLock {
                lastUpdated = cached.lastUpdated
            }

            // Refresh in background if stale
            if await isStale {
                Task {
                    try? await refresh()
                }
            }
            return
        }

        // Try loading from bundled fallback
        if let fallback = try? await loadBundledFallback() {
            await loadFromEntries(fallback)

            // Fetch fresh data in background
            Task {
                try? await refresh()
            }
            return
        }

        // Fetch from source
        try await refresh()
    }

    /// Loads emoji data from raw entries.
    private func loadFromEntries(_ entries: [EmojiRawEntry]) async {
        var newEmojis: [Emoji] = []
        var newByCharacter: [String: Emoji] = [:]
        var newByShortcode: [String: Emoji] = [:]
        var newByCategory: [EmojiCategory: [Emoji]] = [:]

        for entry in entries {
            guard let emoji = entry.toEmoji() else { continue }

            newEmojis.append(emoji)
            newByCharacter[emoji.character] = emoji

            for shortcode in emoji.shortcodes {
                newByShortcode[shortcode.lowercased()] = emoji
            }

            newByCategory[emoji.category, default: []].append(emoji)
        }

        lock.withLock {
            emojis = newEmojis
            byCharacter = newByCharacter
            byShortcode = newByShortcode
            byCategory = newByCategory
            isLoaded = true
            if lastUpdated == nil {
                lastUpdated = Date()
            }
        }
    }

    /// Loads fallback emoji data from custom URL or bundled resource.
    ///
    /// Priority:
    /// 1. Custom fallback URL (if provided in init)
    /// 2. Bundled fallback resource
    ///
    /// The fallback must be in `EmojiRawEntry` JSON format.
    /// Run `swift run BuildEmojiIndex` to generate a compatible file.
    private func loadBundledFallback() async throws -> [EmojiRawEntry]? {
        // Try custom fallback first
        if let customURL = customFallbackURL {
            let data = try Data(contentsOf: customURL)
            return try JSONDecoder().decode([EmojiRawEntry].self, from: data)
        }

        // Fall back to bundled resource
        guard let url = Bundle.module.url(forResource: "emoji-fallback", withExtension: "json") else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([EmojiRawEntry].self, from: data)
    }

    // MARK: - Manual Loading

    /// Manually triggers loading of the emoji index.
    ///
    /// Normally, the index loads automatically on first access.
    /// Use this method to preload data.
    public func load() async throws {
        try await ensureLoaded()
    }

    /// Clears the cache and reloads from the source.
    public func clearCacheAndReload() async throws {
        try await cache.clear(for: source.identifier)
        lock.withLock {
            isLoaded = false
            emojis = []
            byCharacter = [:]
            byShortcode = [:]
            byCategory = [:]
            lastUpdated = nil
        }
        try await refresh()
    }
}
