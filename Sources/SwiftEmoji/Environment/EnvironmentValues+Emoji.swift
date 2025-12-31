import SwiftUI

// MARK: - Environment Keys

private struct EmojiCellSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 44
}

private struct EmojiCellSpacingKey: EnvironmentKey {
    static let defaultValue: CGFloat = 4
}

// MARK: - Environment Values

extension EnvironmentValues {
    /// The size of emoji cells in the grid.
    public var emojiCellSize: CGFloat {
        get { self[EmojiCellSizeKey.self] }
        set { self[EmojiCellSizeKey.self] = newValue }
    }

    /// The spacing between emoji cells in the grid.
    public var emojiCellSpacing: CGFloat {
        get { self[EmojiCellSpacingKey.self] }
        set { self[EmojiCellSpacingKey.self] = newValue }
    }
}
