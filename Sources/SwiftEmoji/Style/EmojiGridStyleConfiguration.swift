import SwiftUI
import SwiftEmojiIndex

/// Configuration passed to `EmojiGridStyle.makeGrid`.
public struct GridConfiguration {
    /// All emojis being displayed (flat list).
    public let emojis: [Emoji]

    /// Emoji sections (when displaying by category).
    /// When non-nil, styles should render section headers.
    public let sections: [EmojiSection]?

    /// Currently selected emoji characters.
    public let selection: Set<String>

    /// Whether selection is enabled.
    public let isSelectable: Bool

    /// Closure to check if an emoji is selected.
    public let isSelected: (Emoji) -> Bool

    /// Closure to handle emoji tap.
    public let onTap: (Emoji) -> Void

    /// Creates a new grid configuration with flat emojis.
    @MainActor
    public init(
        emojis: [Emoji],
        selection: Set<String>,
        isSelectable: Bool,
        isSelected: @escaping (Emoji) -> Bool,
        onTap: @escaping (Emoji) -> Void
    ) {
        self.emojis = emojis
        self.sections = nil
        self.selection = selection
        self.isSelectable = isSelectable
        self.isSelected = isSelected
        self.onTap = onTap
    }

    /// Creates a new grid configuration with sections.
    @MainActor
    public init(
        sections: [EmojiSection],
        selection: Set<String>,
        isSelectable: Bool,
        isSelected: @escaping (Emoji) -> Bool,
        onTap: @escaping (Emoji) -> Void
    ) {
        self.emojis = sections.flatMap(\.emojis)
        self.sections = sections
        self.selection = selection
        self.isSelectable = isSelectable
        self.isSelected = isSelected
        self.onTap = onTap
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

    /// Action to call when tapped.
    public let onTap: () -> Void

    /// Creates a new cell configuration.
    @MainActor
    public init(
        emoji: Emoji,
        isSelected: Bool,
        isSelectable: Bool,
        onTap: @escaping () -> Void
    ) {
        self.emoji = emoji
        self.isSelected = isSelected
        self.isSelectable = isSelectable
        self.onTap = onTap
    }
}

/// Configuration passed to `EmojiGridStyle.makeSectionHeader`.
public struct HeaderConfiguration {
    /// The category for this header.
    public let category: EmojiCategory

    /// Creates a new header configuration.
    public init(category: EmojiCategory) {
        self.category = category
    }
}
