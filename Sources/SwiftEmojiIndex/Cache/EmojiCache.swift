import Foundation

/// Protocol for emoji data caching.
///
/// Implement this protocol to provide custom caching behavior.
/// The package provides `DiskCache` as the default implementation.
public protocol EmojiCache: Sendable {
    /// Loads cached emoji entries for a specific data source.
    ///
    /// - Parameter sourceIdentifier: The data source identifier
    /// - Returns: A tuple containing the entries and the date they were cached, or `nil` if no cache exists
    /// - Throws: `EmojiIndexError.cacheReadFailed` if reading fails
    func load(for sourceIdentifier: String) async throws -> (entries: [EmojiRawEntry], lastUpdated: Date)?

    /// Saves emoji entries to the cache.
    ///
    /// - Parameters:
    ///   - entries: The entries to cache
    ///   - sourceIdentifier: The data source identifier
    /// - Throws: `EmojiIndexError.cacheWriteFailed` if writing fails
    func save(_ entries: [EmojiRawEntry], for sourceIdentifier: String) async throws

    /// Clears the cache for a specific data source.
    ///
    /// - Parameter sourceIdentifier: The data source identifier
    /// - Throws: `EmojiIndexError.cacheWriteFailed` if clearing fails
    func clear(for sourceIdentifier: String) async throws

    /// Clears all cached data.
    ///
    /// - Throws: `EmojiIndexError.cacheWriteFailed` if clearing fails
    func clearAll() async throws
}
