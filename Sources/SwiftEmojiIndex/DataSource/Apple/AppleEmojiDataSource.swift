#if os(macOS)
import Foundation

/// Data source that reads emoji from Apple's private CoreEmoji framework (macOS only).
///
/// This provides localized emoji names from the system. It blends well with
/// `GemojiDataSource` to add shortcodes and keywords.
///
/// ## Usage
///
/// ```swift
/// // Check availability
/// if AppleEmojiDataSource.isAvailable {
///     let source = AppleEmojiDataSource()
///     let provider = EmojiIndexProvider(source: source)
/// }
///
/// // With specific locale
/// let source = AppleEmojiDataSource(locale: .init(identifier: "ja"))
///
/// // List available locales
/// let locales = AppleEmojiDataSource.availableLocales()
/// ```
///
/// ## Blending with Gemoji
///
/// Apple provides localized names, Gemoji provides shortcodes/keywords.
/// Use `BlendedEmojiDataSource` to combine them:
///
/// ```swift
/// let blended = BlendedEmojiDataSource(
///     primary: AppleEmojiDataSource(locale: .current),
///     secondary: GemojiDataSource.shared
/// )
/// ```
public struct AppleEmojiDataSource: EmojiDataSource {
    public let identifier: String
    public let displayName: String
    public let locale: Locale

    private static let frameworkPath = "/System/Library/PrivateFrameworks/CoreEmoji.framework/Versions/A/Resources"

    /// Whether CoreEmoji framework is available on this system.
    public static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: frameworkPath)
    }

    /// Creates an Apple emoji data source with the specified locale.
    ///
    /// - Parameter locale: The locale to use for emoji names. Defaults to current.
    public init(locale: Locale = .current) {
        self.locale = locale
        self.identifier = "apple-\(locale.identifier)"
        self.displayName = "Apple (\(locale.identifier))"
    }

    /// Returns available locales from the CoreEmoji framework.
    public static func availableLocales() -> [Locale] {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(atPath: frameworkPath) else {
            return []
        }

        return contents
            .filter { $0.hasSuffix(".lproj") }
            .map { $0.replacingOccurrences(of: ".lproj", with: "") }
            .map { Locale(identifier: $0) }
            .sorted { $0.identifier < $1.identifier }
    }

    public func fetch() async throws -> [EmojiRawEntry] {
        guard Self.isAvailable else {
            throw EmojiIndexError.sourceUnavailable(reason: "CoreEmoji framework not found")
        }

        guard let names = loadLocalizedNames() else {
            throw EmojiIndexError.sourceUnavailable(reason: "Could not load emoji names for locale \(locale.identifier)")
        }

        return names.compactMap { character, name in
            // Skip skin tone variants
            guard !hasSkinToneModifier(character) else { return nil }

            return EmojiRawEntry(
                character: character,
                name: name,
                category: "Unknown", // Apple doesn't provide categories
                shortcodes: [],
                keywords: generateKeywords(from: name),
                supportsSkinTone: false // Will be enriched by Gemoji
            )
        }
    }

    // MARK: - Private

    private func loadLocalizedNames() -> [String: String]? {
        let fileManager = FileManager.default
        let basePath = Self.frameworkPath

        // Build list of locales to try
        var localesToTry: [String] = []

        // Try exact locale (e.g., "en_GB")
        let localeId = locale.identifier.replacingOccurrences(of: "-", with: "_")
        localesToTry.append(localeId)

        // Try language only (e.g., "en")
        if let language = locale.language.languageCode?.identifier {
            localesToTry.append(language)
        }

        // Try system preferred languages
        localesToTry.append(contentsOf: Locale.preferredLanguages.map {
            $0.replacingOccurrences(of: "-", with: "_")
        })

        // Fallback to English
        localesToTry.append("en")

        for localeId in localesToTry {
            // Try with region
            let path = "\(basePath)/\(localeId).lproj/AppleName.strings"
            if fileManager.fileExists(atPath: path),
               let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                return dict
            }

            // Try base language only
            let baseLanguage = localeId.components(separatedBy: "_").first ?? localeId
            let basePath2 = "\(basePath)/\(baseLanguage).lproj/AppleName.strings"
            if fileManager.fileExists(atPath: basePath2),
               let dict = NSDictionary(contentsOfFile: basePath2) as? [String: String] {
                return dict
            }
        }

        return nil
    }

    private func generateKeywords(from name: String) -> [String] {
        name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func hasSkinToneModifier(_ emoji: String) -> Bool {
        let skinToneModifiers: Set<Unicode.Scalar> = [
            "\u{1F3FB}", // Light
            "\u{1F3FC}", // Medium-Light
            "\u{1F3FD}", // Medium
            "\u{1F3FE}", // Medium-Dark
            "\u{1F3FF}"  // Dark
        ]
        return emoji.unicodeScalars.contains { skinToneModifiers.contains($0) }
    }
}
#endif
