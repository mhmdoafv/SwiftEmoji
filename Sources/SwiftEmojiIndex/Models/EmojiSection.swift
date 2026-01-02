import Foundation

/// A section of emojis grouped by category.
///
/// Use this type when displaying emojis in a sectioned grid or picker.
/// Sections are ordered by `EmojiCategory.allCases`.
public struct EmojiSection: Identifiable, Sendable {
    /// The category for this section.
    public let category: EmojiCategory

    /// The emojis in this section.
    public let emojis: [Emoji]

    /// Unique identifier (the category's id).
    public var id: String { category.id }

    /// Creates an emoji section.
    public init(category: EmojiCategory, emojis: [Emoji]) {
        self.category = category
        self.emojis = emojis
    }
}
