import SwiftUI
import SwiftEmojiIndex

/// A view that displays a single emoji.
///
/// This is the default cell view used by `EmojiGrid`. You can customize
/// its appearance using `EmojiGridStyle.makeCell`.
public struct EmojiCell: View {
    /// The emoji to display.
    public let emoji: Emoji

    /// Whether this cell is selected.
    public let isSelected: Bool

    /// The action to perform when tapped.
    public let action: () -> Void

    /// The size of the emoji font.
    @Environment(\.emojiCellSize) private var cellSize

    /// Creates an emoji cell.
    /// - Parameters:
    ///   - emoji: The emoji to display
    ///   - isSelected: Whether the cell is selected
    ///   - action: The action to perform when tapped
    public init(
        emoji: Emoji,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.emoji = emoji
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(emoji.character)
                .font(.system(size: cellSize * 0.7))
                .frame(width: cellSize, height: cellSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(emoji.name)
    }
}

#Preview {
    HStack {
        EmojiCell(
            emoji: Emoji(
                character: "😀",
                name: "grinning face",
                category: .smileysAndEmotion
            ),
            isSelected: false,
            action: {}
        )

        EmojiCell(
            emoji: Emoji(
                character: "😂",
                name: "face with tears of joy",
                category: .smileysAndEmotion
            ),
            isSelected: true,
            action: {}
        )
    }
    .padding()
}
