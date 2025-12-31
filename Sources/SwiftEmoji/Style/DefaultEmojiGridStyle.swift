import SwiftUI
import SwiftEmojiIndex

/// The default emoji grid style.
///
/// This style renders emojis with minimal styling, passing through
/// the default content unchanged.
public struct DefaultEmojiGridStyle: EmojiGridStyle {
    /// Creates a new default style.
    public init() {}

    public func makeGrid(configuration: GridConfiguration) -> some View {
        configuration.content
    }

    public func makeCell(configuration: CellConfiguration) -> some View {
        configuration.content
    }

    public func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
        configuration.content
    }
}

/// A style that adds selection highlighting to cells.
public struct SelectionHighlightStyle: EmojiGridStyle {
    /// The color to use for selection highlighting.
    public var selectionColor: Color

    /// Creates a new selection highlight style.
    /// - Parameter selectionColor: The color for selection highlighting
    public init(selectionColor: Color = .accentColor) {
        self.selectionColor = selectionColor
    }

    public func makeGrid(configuration: GridConfiguration) -> some View {
        configuration.content
    }

    public func makeCell(configuration: CellConfiguration) -> some View {
        configuration.content
            .background {
                if configuration.isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectionColor.opacity(0.2))
                }
            }
    }

    public func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
        configuration.content
    }
}

/// A style with rounded corners and subtle backgrounds.
public struct RoundedEmojiGridStyle: EmojiGridStyle {
    /// Corner radius for cells.
    public var cornerRadius: CGFloat

    /// Background color for cells.
    public var cellBackground: Color

    /// Selection highlight color.
    public var selectionColor: Color

    /// Creates a new rounded style.
    public init(
        cornerRadius: CGFloat = 8,
        cellBackground: Color = .secondary.opacity(0.1),
        selectionColor: Color = .accentColor
    ) {
        self.cornerRadius = cornerRadius
        self.cellBackground = cellBackground
        self.selectionColor = selectionColor
    }

    public func makeGrid(configuration: GridConfiguration) -> some View {
        configuration.content
    }

    public func makeCell(configuration: CellConfiguration) -> some View {
        configuration.content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(configuration.isSelected ? selectionColor.opacity(0.2) : cellBackground)
            }
            .overlay {
                if configuration.isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(selectionColor, lineWidth: 2)
                }
            }
    }

    public func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
        configuration.content
            .font(.headline)
            .foregroundStyle(.secondary)
    }
}
