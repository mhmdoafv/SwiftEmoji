import Foundation

/// Represents a single emoji with its metadata and searchable attributes.
public struct Emoji: Identifiable, Hashable, Sendable, Codable {
    /// The emoji character itself (e.g., "😀")
    public let character: String

    /// Human-readable name (e.g., "grinning face")
    public let name: String

    /// The category this emoji belongs to
    public let category: EmojiCategory

    /// Shortcodes for this emoji (e.g., ["grinning", "smile"])
    public let shortcodes: [String]

    /// Combined searchable keywords including name words, shortcodes, and tags
    public let keywords: [String]

    /// Whether this emoji supports skin tone modifiers
    public let supportsSkinTone: Bool

    /// Unique identifier - the emoji character itself
    public var id: String { character }

    /// Creates a new Emoji instance.
    /// - Parameters:
    ///   - character: The emoji character
    ///   - name: Human-readable name
    ///   - category: The emoji category
    ///   - shortcodes: Shortcodes for quick lookup
    ///   - keywords: Searchable keywords
    ///   - supportsSkinTone: Whether skin tone modifiers are supported
    public init(
        character: String,
        name: String,
        category: EmojiCategory,
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

// MARK: - Skin Tone Support

extension Emoji {
    /// Returns the emoji with the specified skin tone applied.
    /// If the emoji doesn't support skin tones, returns the original character.
    /// - Parameter skinTone: The skin tone to apply
    /// - Returns: The emoji character with the skin tone modifier applied
    public func withSkinTone(_ skinTone: SkinTone) -> String {
        guard supportsSkinTone, skinTone != .none else {
            return character
        }

        // For simple emojis, append the skin tone modifier
        // For ZWJ sequences, this is more complex and may need special handling
        return character + skinTone.modifier
    }
}

// MARK: - CustomStringConvertible

extension Emoji: CustomStringConvertible {
    public var description: String {
        character
    }
}
