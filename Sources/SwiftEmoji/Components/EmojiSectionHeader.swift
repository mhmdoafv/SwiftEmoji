import SwiftUI
import SwiftEmojiIndex

/// A view that displays a section header for an emoji category.
///
/// This is the default header view used by `EmojiGrid`. You can customize
/// its appearance using `EmojiGridStyle.makeSectionHeader`.
public struct EmojiSectionHeader: View {
    /// The category for this header.
    private let category: EmojiCategory?
    
    private let title: String?
    private let systemImage: String?

    /// Creates a section header.
    /// - Parameter category: The category to display
    public init(category: EmojiCategory) {
        self.category = category
        self.title = nil
        self.systemImage = nil
    }
    
    public init(_ title: String, systemImage: String){
        self.title = title
        self.systemImage = systemImage
        self.category = nil
    }
    
    private var resolvedTitle: String? { category?.displayName ?? title }

    private var resolvedSymbolName: String? { category?.symbolName ?? systemImage }
    
    public var body: some View {
        HStack {
            if let resolvedSymbolName {
                Image(systemName: resolvedSymbolName)
                    .foregroundStyle(.secondary)
            }

            if let resolvedTitle {
                Text(resolvedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        EmojiSectionHeader("Favorites", systemImage: "star")
        ForEach(EmojiCategory.allCases) { category in
            EmojiSectionHeader(category: category)
        }
    }
    .padding()
}
#endif
