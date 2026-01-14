# SwiftEmojiIndex - Data Sources

Custom emoji data sources and blending strategies.

## Quick Start

```swift
struct MySource: EmojiDataSource {
    let identifier = "my-source"
    let displayName = "My Source"

    func fetch() async throws -> [EmojiRawEntry] {
        // Fetch from your source
    }
}

let provider = EmojiIndexProvider(source: MySource())
```

## Built-in Sources

| Source | Description | URL |
|--------|-------------|-----|
| **GemojiDataSource** | Emoji characters, names, shortcodes, keywords | [github/gemoji](https://github.com/github/gemoji) |
| **CLDREmojiDataSource** | Localized names (100+ languages) | [unicode-org/cldr-json](https://github.com/unicode-org/cldr-json) |
| **AppleEmojiDataSource** | macOS only. High-quality localized names | System framework |

## EmojiDataSource Protocol

```swift
public protocol EmojiDataSource: Sendable {
    var identifier: String { get }           // Cache namespace
    var displayName: String { get }
    var remoteURL: URL? { get }              // Optional
    var refreshInterval: TimeInterval { get } // Default: 24 hours

    func fetch() async throws -> [EmojiRawEntry]
}
```

## Blending Sources

Combine multiple sources to get the best of each:

```swift
let blended = BlendedEmojiDataSource(
    primary: CLDREmojiDataSource(locale: .current),  // Localized names
    secondary: GemojiDataSource.shared                // Order, shortcodes, categories
)

let provider = EmojiIndexProvider(source: blended)
```

### Why Blend?

| Source | Provides | Missing |
|--------|----------|---------|
| **Gemoji** | Standard order, shortcodes, keywords, categories | Localized names |
| **CLDR** | Localized names (100+ languages) | Order, shortcodes, categories |
| **Apple** | High-quality localized names (macOS) | Order, shortcodes, categories |

Blending ensures emojis appear in the familiar keyboard order with proper categories while showing localized names.

## Notes

- The `identifier` is used for cache namespacing - different identifiers = separate caches
- `refreshInterval` controls how often stale cache triggers a refetch
- The shared instance uses a pre-configured blended source optimized for each platform
