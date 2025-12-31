import Foundation

/// How search results should be ranked.
public enum SearchRanking: Sendable {
    /// Default relevance-based ranking: exact match > name > shortcode > keyword
    case relevance
    /// Sort by usage frequency/recency (requires EmojiUsageTracker)
    case usage
    /// Sort alphabetically by name
    case alphabetical
}

/// Protocol for emoji index providers.
///
/// An emoji index provides access to emoji data with searching and categorization.
/// The package provides `EmojiIndexProvider` as the default implementation.
///
/// ## Custom Implementations
///
/// You can create custom index implementations for special use cases:
///
/// ```swift
/// class MyCustomIndex: EmojiIndexProtocol {
///     // Custom implementation
/// }
/// ```
public protocol EmojiIndexProtocol: Sendable {
    /// All available emojis.
    ///
    /// - Returns: Array of all emojis
    /// - Throws: `EmojiIndexError` if loading fails
    var allEmojis: [Emoji] { get async throws }

    /// Emojis organized by category.
    ///
    /// - Returns: Dictionary mapping categories to their emojis
    /// - Throws: `EmojiIndexError` if loading fails
    var categories: [EmojiCategory: [Emoji]] { get async throws }

    /// Looks up an emoji by its character.
    ///
    /// - Parameter character: The emoji character to look up
    /// - Returns: The matching emoji, or `nil` if not found
    func emoji(for character: String) async -> Emoji?

    /// Looks up an emoji by its shortcode.
    ///
    /// - Parameter shortcode: The shortcode to look up (e.g., "sob")
    /// - Returns: The matching emoji, or `nil` if not found
    func emoji(forShortcode shortcode: String) async -> Emoji?

    /// Searches for emojis matching a query.
    ///
    /// Search priority (for `.relevance` ranking):
    /// 1. Exact shortcode match (pinned to top)
    /// 2. Name contains query
    /// 3. Shortcode prefix match
    /// 4. Keyword prefix match
    ///
    /// - Parameters:
    ///   - query: The search query
    ///   - ranking: How to rank results (default: `.relevance`)
    /// - Returns: Array of matching emojis
    func search(_ query: String, ranking: SearchRanking) async -> [Emoji]

    /// Get favorite emoji based on usage history.
    ///
    /// - Returns: Emoji sorted by usage frequency/recency
    func favorites() async -> [Emoji]

    /// Refreshes the emoji data from the source.
    ///
    /// - Throws: `EmojiIndexError` if refresh fails
    func refresh() async throws

    /// The date when the index was last updated.
    var lastUpdated: Date? { get async }

    /// Whether the cached data is stale and should be refreshed.
    var isStale: Bool { get async }
}

// MARK: - Default Implementations

extension EmojiIndexProtocol {
    /// Search with default relevance ranking.
    public func search(_ query: String) async -> [Emoji] {
        await search(query, ranking: .relevance)
    }
}
