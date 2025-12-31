import SwiftUI

// MARK: - View Modifiers

extension View {
    /// Sets the size of emoji cells in the grid.
    ///
    /// - Parameter size: The cell size in points
    /// - Returns: A view with the modified cell size
    public func emojiCellSize(_ size: CGFloat) -> some View {
        environment(\.emojiCellSize, size)
    }

    /// Sets the spacing between emoji cells in the grid.
    ///
    /// - Parameter spacing: The spacing in points
    /// - Returns: A view with the modified spacing
    public func emojiCellSpacing(_ spacing: CGFloat) -> some View {
        environment(\.emojiCellSpacing, spacing)
    }
}
