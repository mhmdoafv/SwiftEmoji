import Foundation

/// Protocol for emoji data providers.
///
/// Implement this protocol to create custom emoji data sources.
/// The package provides `GemojiDataSource` as the default implementation.
///
/// ## Creating a Custom Data Source
///
/// ```swift
/// struct MyCustomDataSource: EmojiDataSource {
///     let identifier = "my-custom-source"
///     let displayName = "My Custom Source"
///
///     func fetch() async throws -> [EmojiRawEntry] {
///         // Fetch and return emoji data
///     }
/// }
/// ```
public protocol EmojiDataSource: Sendable {
    /// Unique identifier for this data source.
    ///
    /// Used for cache namespacing to prevent conflicts between different sources.
    var identifier: String { get }

    /// Human-readable name for this data source.
    var displayName: String { get }

    /// The URL to fetch emoji data from, if applicable.
    ///
    /// Return `nil` if the data source doesn't fetch from a URL
    /// (e.g., bundled data only).
    var remoteURL: URL? { get }

    /// Fetch emoji data from this source.
    ///
    /// - Returns: An array of raw emoji entries
    /// - Throws: `EmojiIndexError` if the fetch fails
    func fetch() async throws -> [EmojiRawEntry]

    /// The interval after which cached data should be refreshed.
    ///
    /// Default is 24 hours.
    var refreshInterval: TimeInterval { get }
}

// MARK: - Default Implementations

extension EmojiDataSource {
    /// Default refresh interval of 24 hours.
    public var refreshInterval: TimeInterval {
        24 * 60 * 60
    }

    /// Default remote URL is nil.
    public var remoteURL: URL? {
        nil
    }
}
