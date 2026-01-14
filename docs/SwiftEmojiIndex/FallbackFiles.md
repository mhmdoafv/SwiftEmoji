# SwiftEmojiIndex - Fallback Files

Building and managing fallback JSON files for offline use.

## Quick Start

```bash
swift run BuildEmojiIndex
```

## How Fallback Works

Data loads in this order:
1. **Cache** - Previously fetched data
2. **Fallback** - Bundled or custom fallback file
3. **Remote** - Fresh fetch from data source

## Building Fallbacks

### Interactive Mode

```bash
swift run BuildEmojiIndex
```

Prompts for source type and locales.

### Non-Interactive Mode (CI)

```bash
# Specific locales
swift run BuildEmojiIndex --source blended --locales en,ja,ko,zh

# All available locales
swift run BuildEmojiIndex --source blended --all-locales
```

### Source Recommendations

| Source | Recommended | Description |
|--------|-------------|-------------|
| **CLDR + Gemoji** | Yes | Localized names, standard order, shortcodes |
| **Apple + Gemoji** | Yes (macOS) | Apple localization, standard order, shortcodes |
| **GitHub Gemoji** | No | English only, no localization |
| **Unicode CLDR** | No | No standard order, no shortcodes, no categories |
| **Apple CoreEmoji** | No | No standard order, no shortcodes |

Non-blended sources produce incomplete data (wrong emoji order, missing categories).

## Custom Fallback

```swift
let customFallback = Bundle.main.url(forResource: "my-emojis", withExtension: "json")!

let provider = EmojiIndexProvider(
    source: GemojiDataSource.shared,
    fallbackURL: customFallback
)
```

## File Format

Fallback files must be JSON arrays of `EmojiRawEntry`:

```json
[
  {
    "character": "😀",
    "name": "grinning face",
    "category": "Smileys & Emotion",
    "shortcodes": ["grinning"],
    "keywords": ["face", "grin", "happy"],
    "supportsSkinTone": false
  }
]
```

## Automated Updates

A GitHub Action checks for upstream changes quarterly (Jan, Apr, Jul, Oct) and creates a PR if updates are available.

### Manual Trigger

1. Go to Actions > "Update Emoji Fallbacks"
2. Click "Run workflow"
3. Optionally specify locales (comma-separated) or leave default

## Notes

- Output location: `Sources/SwiftEmojiIndex/Resources/emoji-fallback-{locale}.json`
- Always use **blended** sources for production fallbacks
- The bundled fallback is English; add locale-specific fallbacks as needed
