import Foundation

/// Normalized emoji entry format that all data sources produce.
///
/// This struct provides a unified format for emoji data regardless of the source.
/// Data sources are responsible for transforming their native format into this structure.
public struct EmojiRawEntry: Codable, Sendable, Hashable {
    /// The emoji character (e.g., "😀")
    public let character: String

    /// Human-readable name (e.g., "grinning face")
    public let name: String

    /// Category name (e.g., "Smileys & Emotion")
    public let category: String

    /// Shortcodes for quick lookup (e.g., ["grinning", "smile"])
    public let shortcodes: [String]

    /// Searchable keywords including tags and aliases
    public let keywords: [String]

    /// Whether this emoji supports skin tone modifiers
    public let supportsSkinTone: Bool

    /// Creates a new raw emoji entry.
    /// - Parameters:
    ///   - character: The emoji character
    ///   - name: Human-readable name
    ///   - category: Category name string
    ///   - shortcodes: Shortcodes for quick lookup
    ///   - keywords: Searchable keywords
    ///   - supportsSkinTone: Whether skin tone modifiers are supported
    public init(
        character: String,
        name: String,
        category: String,
        shortcodes: [String] = [],
        keywords: [String] = [],
        supportsSkinTone: Bool = false
    ) {
        self.character = character
        self.name = name
        self.category = category
        self.shortcodes = shortcodes
        self.keywords = keywords
        self.supportsSkinTone = supportsSkinTone
    }
}

// MARK: - Conversion to Emoji

extension EmojiRawEntry {
    /// Converts this raw entry to an `Emoji` instance.
    ///
    /// - Returns: An `Emoji` instance, or `nil` if the category is not recognized
    public func toEmoji() -> Emoji? {
        guard let emojiCategory = EmojiCategory.from(gemojiCategory: category) else {
            return nil
        }

        return Emoji(
            character: character,
            name: name,
            category: emojiCategory,
            shortcodes: shortcodes,
            keywords: keywords,
            supportsSkinTone: supportsSkinTone
        )
    }
}
