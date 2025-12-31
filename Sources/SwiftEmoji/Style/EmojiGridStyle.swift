import SwiftUI
import SwiftEmojiIndex

/// A protocol for customizing the appearance of emoji grids.
///
/// Similar to SwiftUI's `ButtonStyle`, this protocol lets you customize
/// how emoji grids, cells, and headers are rendered.
///
/// ## Creating a Custom Style
///
/// ```swift
/// struct MyCustomStyle: EmojiGridStyle {
///     func makeGrid(configuration: GridConfiguration) -> some View {
///         configuration.content
///             .padding()
///             .background(.ultraThinMaterial)
///     }
///
///     func makeCell(configuration: CellConfiguration) -> some View {
///         configuration.content
///             .scaleEffect(configuration.isSelected ? 1.2 : 1.0)
///     }
///
///     func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
///         configuration.content
///             .font(.headline)
///     }
/// }
/// ```
///
/// ## Applying a Style
///
/// ```swift
/// EmojiGrid(emojis: emojis) { emoji in
///     // handle tap
/// }
/// .emojiGridStyle(MyCustomStyle())
/// ```
public protocol EmojiGridStyle {
    /// The type of view for the grid container.
    associatedtype GridBody: View

    /// The type of view for each emoji cell.
    associatedtype CellBody: View

    /// The type of view for section headers.
    associatedtype HeaderBody: View

    /// Creates the view for the grid container.
    ///
    /// - Parameter configuration: The configuration for the grid
    /// - Returns: A view representing the grid
    @ViewBuilder
    func makeGrid(configuration: GridConfiguration) -> GridBody

    /// Creates the view for an emoji cell.
    ///
    /// - Parameter configuration: The configuration for the cell
    /// - Returns: A view representing the cell
    @ViewBuilder
    func makeCell(configuration: CellConfiguration) -> CellBody

    /// Creates the view for a section header.
    ///
    /// - Parameter configuration: The configuration for the header
    /// - Returns: A view representing the header
    @ViewBuilder
    func makeSectionHeader(configuration: HeaderConfiguration) -> HeaderBody
}
