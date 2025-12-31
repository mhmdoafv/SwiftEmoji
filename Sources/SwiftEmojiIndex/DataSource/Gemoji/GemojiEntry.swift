import Foundation

/// Internal representation of a Gemoji JSON entry.
///
/// This matches the structure of the GitHub Gemoji database:
/// https://github.com/github/gemoji
struct GemojiEntry: Decodable, Sendable {
    /// The emoji character
    let emoji: String

    /// Human-readable description
    let description: String

    /// Category name
    let category: String

    /// Shortcode aliases (e.g., ["grinning", "smile"])
    let aliases: [String]

    /// Additional search tags
    let tags: [String]

    /// Whether the emoji supports skin tone modifiers
    let skinTones: Bool?

    /// Unicode version when the emoji was added
    let unicodeVersion: String?

    /// iOS version when the emoji was added
    let iosVersion: String?

    enum CodingKeys: String, CodingKey {
        case emoji
        case description
        case category
        case aliases
        case tags
        case skinTones = "skin_tones"
        case unicodeVersion = "unicode_version"
        case iosVersion = "ios_version"
    }
}

// MARK: - Conversion to EmojiRawEntry

extension GemojiEntry {
    /// Converts this Gemoji entry to the normalized `EmojiRawEntry` format.
    func toRawEntry() -> EmojiRawEntry {
        // Generate keywords from description words, aliases, and tags
        let descriptionWords = description
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        let allKeywords = Set(descriptionWords + aliases + tags)
            .sorted()

        return EmojiRawEntry(
            character: emoji,
            name: description,
            category: category,
            shortcodes: aliases,
            keywords: allKeywords,
            supportsSkinTone: skinTones ?? false
        )
    }
}
