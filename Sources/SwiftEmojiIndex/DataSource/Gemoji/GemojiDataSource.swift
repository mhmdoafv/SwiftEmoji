import Foundation

/// GitHub Gemoji data source - the default and recommended emoji data source.
///
/// Fetches emoji data from the GitHub Gemoji database, which provides:
/// - Comprehensive emoji list with descriptions
/// - Shortcodes/aliases for quick lookup (e.g., `:sob:` for 😭)
/// - Search tags and keywords
/// - Skin tone support information
///
/// ## Usage
///
/// ```swift
/// let provider = EmojiIndexProvider(source: GemojiDataSource.shared)
/// ```
///
/// ## Data Source
///
/// Data is fetched from:
/// https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json
public struct GemojiDataSource: EmojiDataSource, Sendable {
    /// Shared instance of the Gemoji data source.
    public static let shared = GemojiDataSource()

    /// Unique identifier for cache namespacing.
    public let identifier = "gemoji"

    /// Human-readable name.
    public let displayName = "GitHub Gemoji"

    /// The URL to fetch emoji data from.
    public var remoteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json")
    }

    /// Creates a new Gemoji data source.
    public init() {}

    /// Fetches emoji data from the GitHub Gemoji database.
    ///
    /// - Returns: An array of normalized emoji entries
    /// - Throws: `EmojiIndexError` if the fetch fails
    public func fetch() async throws -> [EmojiRawEntry] {
        guard let url = remoteURL else {
            throw EmojiIndexError.invalidURL("Gemoji URL is nil")
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw EmojiIndexError.networkUnavailable(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmojiIndexError.invalidResponse(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw EmojiIndexError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        let entries: [GemojiEntry]
        do {
            entries = try JSONDecoder().decode([GemojiEntry].self, from: data)
        } catch {
            throw EmojiIndexError.decodingFailed(underlying: error)
        }

        guard !entries.isEmpty else {
            throw EmojiIndexError.emptyData
        }

        return entries.map { $0.toRawEntry() }
    }
}
