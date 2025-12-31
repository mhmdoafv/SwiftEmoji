import SwiftUI
import SwiftEmojiIndex

/// Configuration passed to `EmojiGridStyle.makeGrid`.
public struct GridConfiguration {
    /// All emojis being displayed.
    public let emojis: [Emoji]

    /// Categories being displayed, if sectioned.
    public let categories: [EmojiCategory]?

    /// Currently selected emoji characters.
    public let selection: Set<String>

    /// Whether selection is enabled.
    public let isSelectable: Bool

    /// The default grid content.
    public let content: AnyView

    /// Creates a new grid configuration.
    public init(
        emojis: [Emoji],
        categories: [EmojiCategory]?,
        selection: Set<String>,
        isSelectable: Bool,
        content: AnyView
    ) {
        self.emojis = emojis
        self.categories = categories
        self.selection = selection
        self.isSelectable = isSelectable
        self.content = content
    }
}

/// Configuration passed to `EmojiGridStyle.makeCell`.
public struct CellConfiguration {
    /// The emoji for this cell.
    public let emoji: Emoji

    /// Whether this emoji is currently selected.
    public let isSelected: Bool

    /// Whether selection is enabled for the grid.
    public let isSelectable: Bool

    /// The default cell content.
    public let content: AnyView

    /// Creates a new cell configuration.
    public init(
        emoji: Emoji,
        isSelected: Bool,
        isSelectable: Bool,
        content: AnyView
    ) {
        self.emoji = emoji
        self.isSelected = isSelected
        self.isSelectable = isSelectable
        self.content = content
    }
}

/// Configuration passed to `EmojiGridStyle.makeSectionHeader`.
public struct HeaderConfiguration {
    /// The category for this header.
    public let category: EmojiCategory

    /// The default header content.
    public let content: AnyView

    /// Creates a new header configuration.
    public init(
        category: EmojiCategory,
        content: AnyView
    ) {
        self.category = category
        self.content = content
    }
}
