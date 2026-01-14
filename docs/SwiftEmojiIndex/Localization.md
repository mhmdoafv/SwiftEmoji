# SwiftEmojiIndex - Localization

Localized emoji names in 100+ languages via Unicode CLDR and Apple CoreEmoji.

## Quick Start

```swift
// Uses system locale automatically
let provider = EmojiIndexProvider.shared

// Change locale dynamically
await provider.setLocale(Locale(identifier: "ja"))
```

## Locale Manager

```swift
let localeManager = EmojiLocaleManager.shared

// Fetch available locales (async)
let available = await localeManager.fetchAvailableLocales()

// Or use cached (sync, may be incomplete until fetched)
let cached = localeManager.availableLocales

// Set preferred locale (auto-persists to UserDefaults)
localeManager.preferredLocale = Locale(identifier: "ja")

// Get effective locale (preferred or system)
let current = localeManager.effectiveLocale

// Platform-specific locale lists
let cldrLocales = localeManager.cldrLocales      // All platforms
let appleLocales = localeManager.appleLocales    // macOS only
```

## Unicode CLDR (All Platforms)

```swift
// Japanese emoji names - works on all Apple platforms
let source = CLDREmojiDataSource(locale: Locale(identifier: "ja"))
let provider = EmojiIndexProvider(source: source)

// With Gemoji shortcodes
let blended = BlendedEmojiDataSource(
    primary: CLDREmojiDataSource(locale: .current),
    secondary: GemojiDataSource.shared
)

// Fetch available locales (async, cached for 7 days)
let locales = await CLDREmojiDataSource.fetchAvailableLocales()
```

## Apple CoreEmoji (macOS Only)

Higher quality localized names via Apple's private framework.

```swift
#if os(macOS)
import SwiftEmoji

// Check availability
if AppleEmojiDataSource.isAvailable {
    let source = AppleEmojiDataSource(locale: .current)
    let provider = EmojiIndexProvider(source: source)
}

// List available locales
let locales = AppleEmojiDataSource.availableLocales()
// [en, ja, fr, de, es, ...]
#endif
```

### Blending with Gemoji

Combine Apple's localized names with Gemoji's shortcodes:

```swift
#if os(macOS)
let blended = BlendedEmojiDataSource(
    primary: AppleEmojiDataSource(locale: .current),  // Localized names
    secondary: GemojiDataSource.shared                 // Shortcodes + keywords
)
let provider = EmojiIndexProvider(source: blended)
#endif
```

## Notes

- The shared instance automatically picks the best source for your platform
- macOS uses Apple CoreEmoji + Gemoji
- iOS/tvOS/watchOS/visionOS use Unicode CLDR + Gemoji
- Locale changes trigger automatic data reload
