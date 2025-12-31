import SwiftUI
import SwiftEmojiIndex

/// A grid view for displaying and selecting emojis.
///
/// `EmojiGrid` provides a flexible way to display emojis in a grid layout.
/// It does NOT include a ScrollView - you wrap it yourself for full control.
///
/// ## Selection Modes
///
/// The grid supports three interaction patterns:
///
/// ### Tap-only (no selection state)
/// ```swift
/// ScrollView {
///     EmojiGrid(emojis: emojis) { emoji in
///         // Handle tap - e.g., add to canvas and dismiss
///         canvas.add(emoji)
///         dismiss()
///     }
/// }
/// ```
///
/// ### Single selection
/// ```swift
/// @State private var selected: Emoji?
///
/// ScrollView {
///     EmojiGrid(emojis: emojis, selection: $selected)
/// }
/// ```
///
/// ### Multiple selection
/// ```swift
/// @State private var selected: Set<String> = []
///
/// ScrollView {
///     EmojiGrid(emojis: emojis, selection: $selected)
/// }
/// ```
///
/// ## Styling
///
/// Use `emojiGridStyle(_:)` to customize the appearance:
///
/// ```swift
/// EmojiGrid(emojis: emojis) { emoji in }
///     .emojiGridStyle(RoundedEmojiGridStyle())
/// ```
public struct EmojiGrid: View {
    // MARK: - Properties

    private let emojis: [Emoji]
    private let columns: [GridItem]
    private let onTap: ((Emoji) -> Void)?
    private let selectionMode: SelectionMode

    @Binding private var singleSelection: Emoji?
    @Binding private var multipleSelection: Set<String>

    @Environment(\.emojiCellSize) private var cellSize
    @Environment(\.emojiCellSpacing) private var spacing

    // MARK: - Selection Mode

    private enum SelectionMode {
        case none
        case single
        case multiple
    }

    // MARK: - Initializers

    /// Creates an emoji grid with tap-only interaction (no selection state).
    ///
    /// Use this initializer when you want to respond to taps without maintaining
    /// selection state, such as in a picker sheet.
    ///
    /// - Parameters:
    ///   - emojis: The emojis to display
    ///   - columns: Custom grid columns (default: adaptive)
    ///   - onTap: Called when an emoji is tapped
    public init(
        emojis: [Emoji],
        columns: [GridItem]? = nil,
        onTap: @escaping (Emoji) -> Void
    ) {
        self.emojis = emojis
        self.columns = columns ?? [GridItem(.adaptive(minimum: 44))]
        self.onTap = onTap
        self.selectionMode = .none
        self._singleSelection = .constant(nil)
        self._multipleSelection = .constant([])
    }

    /// Creates an emoji grid with single selection.
    ///
    /// - Parameters:
    ///   - emojis: The emojis to display
    ///   - columns: Custom grid columns (default: adaptive)
    ///   - selection: Binding to the selected emoji
    public init(
        emojis: [Emoji],
        columns: [GridItem]? = nil,
        selection: Binding<Emoji?>
    ) {
        self.emojis = emojis
        self.columns = columns ?? [GridItem(.adaptive(minimum: 44))]
        self.onTap = nil
        self.selectionMode = .single
        self._singleSelection = selection
        self._multipleSelection = .constant([])
    }

    /// Creates an emoji grid with multiple selection.
    ///
    /// - Parameters:
    ///   - emojis: The emojis to display
    ///   - columns: Custom grid columns (default: adaptive)
    ///   - selection: Binding to the set of selected emoji IDs
    public init(
        emojis: [Emoji],
        columns: [GridItem]? = nil,
        selection: Binding<Set<String>>
    ) {
        self.emojis = emojis
        self.columns = columns ?? [GridItem(.adaptive(minimum: 44))]
        self.onTap = nil
        self.selectionMode = .multiple
        self._singleSelection = .constant(nil)
        self._multipleSelection = selection
    }

    // MARK: - Body

    public var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(emojis) { emoji in
                cellView(for: emoji)
            }
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func cellView(for emoji: Emoji) -> some View {
        let isSelected = isEmojiSelected(emoji)

        EmojiCell(
            emoji: emoji,
            isSelected: isSelected,
            action: { handleTap(emoji) }
        )
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.2))
            }
        }
    }

    private func isEmojiSelected(_ emoji: Emoji) -> Bool {
        switch selectionMode {
        case .none:
            return false
        case .single:
            return singleSelection?.id == emoji.id
        case .multiple:
            return multipleSelection.contains(emoji.id)
        }
    }

    private func handleTap(_ emoji: Emoji) {
        switch selectionMode {
        case .none:
            onTap?(emoji)

        case .single:
            if singleSelection?.id == emoji.id {
                singleSelection = nil
            } else {
                singleSelection = emoji
            }

        case .multiple:
            if multipleSelection.contains(emoji.id) {
                multipleSelection.remove(emoji.id)
            } else {
                multipleSelection.insert(emoji.id)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
private struct PreviewWrapper: View {
    @State private var singleSelection: Emoji?
    @State private var multipleSelection: Set<String> = []

    let sampleEmojis = [
        Emoji(character: "😀", name: "grinning face", category: .smileysAndEmotion),
        Emoji(character: "😂", name: "face with tears of joy", category: .smileysAndEmotion),
        Emoji(character: "🥹", name: "face holding back tears", category: .smileysAndEmotion),
        Emoji(character: "😍", name: "smiling face with heart-eyes", category: .smileysAndEmotion),
        Emoji(character: "🤔", name: "thinking face", category: .smileysAndEmotion),
        Emoji(character: "😎", name: "smiling face with sunglasses", category: .smileysAndEmotion),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Tap-only mode")
                .font(.headline)
            ScrollView(.horizontal) {
                EmojiGrid(
                    emojis: sampleEmojis,
                    columns: [GridItem(.flexible())]
                ) { emoji in
                    print("Tapped: \(emoji.character)")
                }
            }

            Text("Single selection: \(singleSelection?.character ?? "none")")
                .font(.headline)
            EmojiGrid(emojis: sampleEmojis, selection: $singleSelection)

            Text("Multiple selection: \(multipleSelection.count) selected")
                .font(.headline)
            EmojiGrid(emojis: sampleEmojis, selection: $multipleSelection)
        }
        .padding()
    }
}

#Preview {
    PreviewWrapper()
}
#endif
