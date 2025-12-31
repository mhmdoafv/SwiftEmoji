import SwiftUI
import SwiftEmojiIndex

/// A view that displays a section header for an emoji category.
///
/// This is the default header view used by `EmojiGrid`. You can customize
/// its appearance using `EmojiGridStyle.makeSectionHeader`.
public struct EmojiSectionHeader: View {
    /// The category for this header.
    public let category: EmojiCategory

    /// Creates a section header.
    /// - Parameter category: The category to display
    public init(category: EmojiCategory) {
        self.category = category
    }

    public var body: some View {
        HStack {
            Image(systemName: category.symbolName)
                .foregroundStyle(.secondary)

            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ForEach(EmojiCategory.allCases) { category in
            EmojiSectionHeader(category: category)
        }
    }
    .padding()
}
#endif
