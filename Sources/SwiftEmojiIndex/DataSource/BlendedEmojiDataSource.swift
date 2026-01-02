import Foundation

/// A data source that blends two sources, using one for names and another for order/metadata.
///
/// Useful for combining Apple's localized names with Gemoji's standard order and shortcodes.
///
/// ## Usage
///
/// ```swift
/// #if os(macOS)
/// let blended = BlendedEmojiDataSource(
///     primary: AppleEmojiDataSource(locale: .current),
///     secondary: GemojiDataSource.shared
/// )
/// let provider = EmojiIndexProvider(source: blended)
/// #endif
/// ```
///
/// ## Blending Behavior
///
/// - Secondary source provides: ORDER, shortcodes, keywords, supportsSkinTone, category
/// - Primary source provides: localized name
/// - Emoji only in primary (not yet in secondary) are appended at the end
public struct BlendedEmojiDataSource: EmojiDataSource {
    public let identifier: String
    public let displayName: String

    private let primary: any EmojiDataSource
    private let secondary: any EmojiDataSource

    /// Creates a blended data source.
    ///
    /// - Parameters:
    ///   - primary: The main source (provides names, categories)
    ///   - secondary: The enrichment source (provides shortcodes, keywords)
    public init(primary: any EmojiDataSource, secondary: any EmojiDataSource) {
        self.primary = primary
        self.secondary = secondary
        self.identifier = "\(primary.identifier)+\(secondary.identifier)"
        self.displayName = "\(primary.displayName) + \(secondary.displayName)"
    }

    public var refreshInterval: TimeInterval {
        min(primary.refreshInterval, secondary.refreshInterval)
    }

    public func fetch() async throws -> [EmojiRawEntry] {
        // Fetch from both sources
        let primaryEntries = try await primary.fetch()
        let secondaryEntries = try await secondary.fetch()

        #if DEBUG
        print("[BlendedEmojiDataSource] Primary (\(primary.identifier)): \(primaryEntries.count) entries")
        print("[BlendedEmojiDataSource] Secondary (\(secondary.identifier)): \(secondaryEntries.count) entries")
        if let first = primaryEntries.first {
            print("[BlendedEmojiDataSource] Primary first: \(first.character) = \"\(first.name)\"")
        }
        #endif

        // Index primary by character for fast lookup (provides localized names)
        var primaryByChar: [String: EmojiRawEntry] = [:]
        for entry in primaryEntries {
            primaryByChar[entry.character] = entry
        }

        // Blend: use secondary's ORDER (standard emoji order), enriched with primary's names
        var results: [EmojiRawEntry] = []
        var seen = Set<String>()

        for entry in secondaryEntries {
            seen.insert(entry.character)

            if let localized = primaryByChar[entry.character] {
                // Merge: primary's localized name + secondary's order/shortcodes/keywords
                let merged = EmojiRawEntry(
                    character: entry.character,
                    name: localized.name,
                    category: entry.category != "Unknown" ? entry.category : localized.category,
                    shortcodes: entry.shortcodes,
                    keywords: mergeKeywords(localized.keywords, entry.keywords),
                    supportsSkinTone: entry.supportsSkinTone
                )
                results.append(merged)
            } else {
                results.append(entry)
            }
        }

        // Add any emoji only in primary (new emoji not yet in secondary)
        for entry in primaryEntries {
            if !seen.contains(entry.character) {
                results.append(entry)
            }
        }

        #if DEBUG
        if let first = results.first {
            print("[BlendedEmojiDataSource] Result first: \(first.character) = \"\(first.name)\"")
        }
        print("[BlendedEmojiDataSource] Total blended: \(results.count) entries")
        #endif

        return results
    }

    private func mergeKeywords(_ a: [String], _ b: [String]) -> [String] {
        var set = Set(a)
        set.formUnion(b)
        return Array(set)
    }
}
