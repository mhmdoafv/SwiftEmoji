import Foundation

/// Manages emoji locale preferences and available locales.
///
/// ## Usage
///
/// ```swift
/// let manager = EmojiLocaleManager.shared
///
/// // Get available locales (on macOS, from CoreEmoji)
/// let available = manager.availableLocales
///
/// // Set preferred locale
/// manager.preferredLocale = Locale(identifier: "ja")
///
/// // Get current effective locale
/// let current = manager.effectiveLocale
/// ```
@Observable
public final class EmojiLocaleManager: @unchecked Sendable {
    /// Shared instance.
    public static let shared = EmojiLocaleManager()

    private let storageKey = "SwiftEmojiIndex.preferredLocale"
    private let lock = NSLock()

    /// The user's preferred locale for emoji names.
    /// Set to `nil` to use system locale.
    public var preferredLocale: Locale? {
        didSet {
            if let locale = preferredLocale {
                UserDefaults.standard.set(locale.identifier, forKey: storageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: storageKey)
            }
        }
    }

    /// The effective locale (preferred or system).
    public var effectiveLocale: Locale {
        preferredLocale ?? .current
    }

    /// Available locales for emoji data.
    ///
    /// On macOS, this returns locales available in CoreEmoji.
    /// On other platforms, returns common locales (for custom sources).
    public var availableLocales: [Locale] {
        #if os(macOS)
        return appleAvailableLocales()
        #else
        return commonLocales
        #endif
    }

    /// Whether localized emoji names are available on this platform.
    public var isLocalizationAvailable: Bool {
        #if os(macOS)
        return AppleEmojiDataSource.isAvailable
        #else
        return false // Unless using a custom localized source
        #endif
    }

    private init() {
        // Load saved preference
        if let saved = UserDefaults.standard.string(forKey: storageKey) {
            preferredLocale = Locale(identifier: saved)
        }
    }

    #if os(macOS)
    private func appleAvailableLocales() -> [Locale] {
        AppleEmojiDataSource.availableLocales()
    }
    #endif

    /// Common locales for reference (doesn't mean data is available).
    private let commonLocales: [Locale] = [
        Locale(identifier: "en"),
        Locale(identifier: "es"),
        Locale(identifier: "fr"),
        Locale(identifier: "de"),
        Locale(identifier: "it"),
        Locale(identifier: "pt"),
        Locale(identifier: "ja"),
        Locale(identifier: "ko"),
        Locale(identifier: "zh-Hans"),
        Locale(identifier: "zh-Hant"),
        Locale(identifier: "ar"),
        Locale(identifier: "ru"),
    ]
}

// MARK: - Locale Helpers

extension Locale {
    /// Display name for this locale in the user's current language.
    public var localizedDisplayName: String {
        Locale.current.localizedString(forIdentifier: identifier) ?? identifier
    }

    /// Display name in this locale's own language.
    public var nativeDisplayName: String {
        localizedString(forIdentifier: identifier) ?? identifier
    }
}
