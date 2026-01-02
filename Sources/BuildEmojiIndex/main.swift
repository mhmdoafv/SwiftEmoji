/// BuildEmojiIndex - CLI to build offline fallback emoji indexes
///
/// Usage:
///   swift run BuildEmojiIndex                    # Interactive mode
///   swift run BuildEmojiIndex --help             # Show help
///   swift run BuildEmojiIndex --source blended --locales en,ja,ko
///   swift run BuildEmojiIndex --source blended --all-locales
///
/// Recommended (works on Linux/CI, matches app defaults):
///   blended - CLDR + Gemoji (localized, standard order) [default]
///
/// Other sources (not recommended):
///   gemoji - GitHub Gemoji (English only)
///   cldr   - Unicode CLDR (no standard order)
///   apple* - macOS only, not available on Linux/CI

import Foundation
import SwiftEmojiIndex

// MARK: - Command Line Arguments

struct CLIOptions {
    var source: String?
    var locales: [String]?
    var allLocales: Bool = false
    var help: Bool = false

    static func parse(_ args: [String]) -> CLIOptions {
        var options = CLIOptions()
        var i = 1 // Skip program name

        while i < args.count {
            let arg = args[i]

            switch arg {
            case "--help", "-h":
                options.help = true
            case "--source", "-s":
                i += 1
                if i < args.count {
                    options.source = args[i]
                }
            case "--locales", "-l":
                i += 1
                if i < args.count {
                    options.locales = args[i].split(separator: ",").map { String($0) }
                }
            case "--all-locales", "-a":
                options.allLocales = true
            default:
                break
            }
            i += 1
        }

        return options
    }

    var isNonInteractive: Bool {
        source != nil
    }
}

func printHelp() {
    let recommendedSources = """
      blended       CLDR + Gemoji (localized, standard order) [default]
    """

    var otherSources = """
      gemoji        GitHub Gemoji (English only)
      cldr          Unicode CLDR (localized, no standard order)
    """

    #if os(macOS)
    otherSources += """

      apple-blended Apple + Gemoji (macOS, standard order)
      apple         Apple CoreEmoji (macOS, no standard order)
    """
    #endif

    print("""
    BuildEmojiIndex - Build offline fallback emoji indexes

    USAGE:
      swift run BuildEmojiIndex [OPTIONS]

    OPTIONS:
      -h, --help              Show this help message
      -s, --source <SOURCE>   Data source to use (see below)
      -l, --locales <CODES>   Comma-separated locale codes (e.g., en,ja,ko)
      -a, --all-locales       Build all available locales

    RECOMMENDED SOURCES (matches app defaults, standard emoji order):
    \(recommendedSources)

    OTHER SOURCES (no standard emoji order):
    \(otherSources)

    EXAMPLES:
      # Interactive mode (recommended)
      swift run BuildEmojiIndex

      # Build specific locales (recommended)
      swift run BuildEmojiIndex --source blended --locales en,ja,ko,zh

      # Build all available locales
      swift run BuildEmojiIndex --source blended --all-locales

    FILES:
      Output is written to Sources/SwiftEmojiIndex/Resources/
      - emoji-fallback.json (English/default)
      - emoji-fallback-{locale}.json (other locales)
    """)
}

// MARK: - CLI Helpers

func printHeader(_ text: String) {
    print("\n\u{001B}[1m\(text)\u{001B}[0m")
    print(String(repeating: "─", count: 50))
}

func printOption(_ number: Int, _ text: String) {
    print("  \(number). \(text)")
}

func prompt(_ message: String) -> String {
    print("\n\(message) ", terminator: "")
    return readLine() ?? ""
}

func promptChoice(_ message: String, options: [String]) -> Int? {
    print("\n\(message)")
    for (i, option) in options.enumerated() {
        printOption(i + 1, option)
    }
    print()
    guard let input = readLine(), let choice = Int(input), choice >= 1, choice <= options.count else {
        return nil
    }
    return choice
}

func promptMultiChoice(_ message: String, options: [String]) -> [Int] {
    print("\n\(message)")
    for (i, option) in options.enumerated() {
        printOption(i + 1, option)
    }
    print("\nEnter numbers separated by spaces (e.g., '1 3 5'), or 'all': ", terminator: "")

    guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
        return []
    }

    if input.lowercased() == "all" {
        return Array(1...options.count)
    }

    return input.split(separator: " ").compactMap { Int($0) }.filter { $0 >= 1 && $0 <= options.count }
}

func promptLocaleCodes(_ message: String, available: [String: String]) -> [String] {
    print("\n\(message)")
    print("\nAvailable locales:")
    let sortedKeys = available.keys.sorted()
    for key in sortedKeys {
        print("  \(key) - \(available[key]!)")
    }
    print("\nEnter locale codes separated by spaces (e.g., 'en ja fr'), or 'all': ", terminator: "")

    guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
        return []
    }

    if input.lowercased() == "all" {
        return sortedKeys
    }

    let requested = input.split(separator: " ").map { String($0) }
    return requested.filter { available.keys.contains($0) }
}

// MARK: - Data Structures

struct GemojiEntry: Decodable {
    let emoji: String
    let description: String
    let category: String
    let aliases: [String]
    let tags: [String]
    let skinTones: Bool?

    enum CodingKeys: String, CodingKey {
        case emoji, description, category, aliases, tags
        case skinTones = "skin_tones"
    }
}

struct CLDRAnnotationsRoot: Decodable {
    let annotations: CLDRAnnotationsContainer

    struct CLDRAnnotationsContainer: Decodable {
        let annotations: [String: CLDRAnnotation]
    }
}

struct CLDRAnnotation: Decodable {
    let `default`: [String]?
    let tts: [String]?
}

struct FallbackEntry: Codable {
    let character: String
    let name: String
    let category: String
    let shortcodes: [String]
    let keywords: [String]
    let supportsSkinTone: Bool
}

// MARK: - Sources

enum Source: String, CaseIterable {
    case blended = "CLDR + Gemoji (localized, standard order) [RECOMMENDED]"
    case gemoji = "GitHub Gemoji (English only, no localization)"
    case cldr = "Unicode CLDR (localized, NO standard order)"
    #if os(macOS)
    case appleBlended = "Apple + Gemoji (macOS, standard order)"
    case apple = "Apple CoreEmoji (macOS, NO standard order)"
    #endif
}

let commonLocales = [
    "en": "English",
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "it": "Italian",
    "pt": "Portuguese",
    "ja": "Japanese",
    "ko": "Korean",
    "zh": "Chinese (Simplified)",
    "zh-Hant": "Chinese (Traditional)",
    "ar": "Arabic",
    "ru": "Russian",
    "hi": "Hindi",
    "th": "Thai",
    "vi": "Vietnamese",
    "id": "Indonesian",
    "ms": "Malay",
    "tr": "Turkish",
    "pl": "Polish",
    "nl": "Dutch",
    "sv": "Swedish",
    "da": "Danish",
    "fi": "Finnish",
    "no": "Norwegian",
    "uk": "Ukrainian",
    "cs": "Czech",
    "el": "Greek",
    "he": "Hebrew",
    "hu": "Hungarian",
    "ro": "Romanian"
]

// MARK: - Fetchers

func fetchGemoji() async throws -> [GemojiEntry] {
    let url = URL(string: "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json")!
    print("  Fetching from GitHub Gemoji...")
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([GemojiEntry].self, from: data)
}

func fetchCLDR(locale: String) async throws -> [String: CLDRAnnotation] {
    let url = URL(string: "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/\(locale)/annotations.json")!
    print("  Fetching CLDR annotations for '\(locale)'...")
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NSError(domain: "CLDR", code: 404, userInfo: [NSLocalizedDescriptionKey: "Locale '\(locale)' not found"])
    }

    let root = try JSONDecoder().decode(CLDRAnnotationsRoot.self, from: data)
    return root.annotations.annotations
}

#if os(macOS)
func fetchApple(locale: String) async throws -> [EmojiRawEntry] {
    print("  Fetching from Apple CoreEmoji for '\(locale)'...")

    guard AppleEmojiDataSource.isAvailable else {
        throw NSError(domain: "Apple", code: 1, userInfo: [NSLocalizedDescriptionKey: "CoreEmoji framework not available"])
    }

    let source = AppleEmojiDataSource(locale: Locale(identifier: locale))
    return try await source.fetch()
}

func appleAvailableLocales() -> [String: String] {
    guard AppleEmojiDataSource.isAvailable else { return [:] }

    var result: [String: String] = [:]
    for locale in AppleEmojiDataSource.availableLocales() {
        let name = Locale.current.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
        result[locale.identifier] = name
    }
    return result
}
#endif

// MARK: - Builders

func buildFromGemoji(_ entries: [GemojiEntry]) -> [FallbackEntry] {
    entries.map { entry in
        let descriptionWords = entry.description
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        let allKeywords = Set(descriptionWords + entry.aliases + entry.tags).sorted()

        return FallbackEntry(
            character: entry.emoji,
            name: entry.description,
            category: entry.category,
            shortcodes: entry.aliases,
            keywords: allKeywords,
            supportsSkinTone: entry.skinTones ?? false
        )
    }
}

#if os(macOS)
func buildFromApple(_ entries: [EmojiRawEntry], gemojiEntries: [GemojiEntry]?) -> [FallbackEntry] {
    // Index Apple entries by character for fast lookup
    var appleByChar: [String: EmojiRawEntry] = [:]
    for entry in entries {
        appleByChar[entry.character] = entry
    }

    // If we have Gemoji, use its ORDER and enrich with Apple names
    if let gemoji = gemojiEntries {
        var results: [FallbackEntry] = []
        var seen = Set<String>()

        // Iterate in Gemoji order (standard emoji order)
        for gemojiEntry in gemoji {
            seen.insert(gemojiEntry.emoji)

            if let apple = appleByChar[gemojiEntry.emoji] {
                // Apple name + Gemoji metadata
                results.append(FallbackEntry(
                    character: gemojiEntry.emoji,
                    name: apple.name,
                    category: gemojiEntry.category,
                    shortcodes: gemojiEntry.aliases,
                    keywords: Array(Set(apple.keywords + gemojiEntry.tags)).sorted(),
                    supportsSkinTone: gemojiEntry.skinTones ?? false
                ))
            } else {
                // Gemoji only
                results.append(FallbackEntry(
                    character: gemojiEntry.emoji,
                    name: gemojiEntry.description,
                    category: gemojiEntry.category,
                    shortcodes: gemojiEntry.aliases,
                    keywords: gemojiEntry.tags.sorted(),
                    supportsSkinTone: gemojiEntry.skinTones ?? false
                ))
            }
        }

        // Add any Apple-only emoji at the end
        for entry in entries {
            if !seen.contains(entry.character) {
                results.append(FallbackEntry(
                    character: entry.character,
                    name: entry.name,
                    category: entry.category,
                    shortcodes: entry.shortcodes,
                    keywords: entry.keywords.sorted(),
                    supportsSkinTone: entry.supportsSkinTone
                ))
            }
        }

        return results
    }

    // No Gemoji - just return Apple entries (no guaranteed order)
    return entries.map { entry in
        FallbackEntry(
            character: entry.character,
            name: entry.name,
            category: entry.category,
            shortcodes: entry.shortcodes,
            keywords: entry.keywords.sorted(),
            supportsSkinTone: entry.supportsSkinTone
        )
    }
}
#endif

func buildFromCLDR(_ annotations: [String: CLDRAnnotation], gemojiEntries: [GemojiEntry]?) -> [FallbackEntry] {
    let skinToneModifiers: Set<Unicode.Scalar> = [
        "\u{1F3FB}", "\u{1F3FC}", "\u{1F3FD}", "\u{1F3FE}", "\u{1F3FF}"
    ]

    // If we have Gemoji, use its ORDER and enrich with CLDR names
    if let gemoji = gemojiEntries {
        // Index CLDR by character for fast lookup
        var cldrByChar: [String: CLDRAnnotation] = [:]
        for (character, annotation) in annotations {
            cldrByChar[character] = annotation
        }

        var results: [FallbackEntry] = []
        var seen = Set<String>()

        // Iterate in Gemoji order (standard emoji order)
        for gemojiEntry in gemoji {
            seen.insert(gemojiEntry.emoji)

            if let cldr = cldrByChar[gemojiEntry.emoji] {
                // CLDR name + Gemoji metadata
                let name = cldr.tts?.first ?? gemojiEntry.description
                let keywords = cldr.default ?? []

                results.append(FallbackEntry(
                    character: gemojiEntry.emoji,
                    name: name,
                    category: gemojiEntry.category,
                    shortcodes: gemojiEntry.aliases,
                    keywords: Array(Set(keywords + gemojiEntry.tags)).sorted(),
                    supportsSkinTone: gemojiEntry.skinTones ?? false
                ))
            } else {
                // Gemoji only
                results.append(FallbackEntry(
                    character: gemojiEntry.emoji,
                    name: gemojiEntry.description,
                    category: gemojiEntry.category,
                    shortcodes: gemojiEntry.aliases,
                    keywords: gemojiEntry.tags.sorted(),
                    supportsSkinTone: gemojiEntry.skinTones ?? false
                ))
            }
        }

        // Add any CLDR-only emoji at the end (rare, but possible for new emoji)
        for (character, annotation) in annotations {
            if character.unicodeScalars.contains(where: { skinToneModifiers.contains($0) }) {
                continue
            }
            if !seen.contains(character) {
                let name = annotation.tts?.first ?? character
                let keywords = annotation.default ?? []

                results.append(FallbackEntry(
                    character: character,
                    name: name,
                    category: "Unknown",
                    shortcodes: [],
                    keywords: keywords.sorted(),
                    supportsSkinTone: false
                ))
            }
        }

        return results
    }

    // No Gemoji - fall back to codepoint order (no standard order)
    var entries: [FallbackEntry] = []

    for (character, annotation) in annotations {
        if character.unicodeScalars.contains(where: { skinToneModifiers.contains($0) }) {
            continue
        }

        let name = annotation.tts?.first ?? character
        let keywords = annotation.default ?? []

        entries.append(FallbackEntry(
            character: character,
            name: name,
            category: "Unknown",
            shortcodes: [],
            keywords: keywords.sorted(),
            supportsSkinTone: false
        ))
    }

    return entries.sorted { $0.character < $1.character }
}

func findPackageRoot(sourceFile: String = #file) -> URL? {
    let fm = FileManager.default

    // Try 1: Walk up from source file location (works in Xcode)
    var current = URL(fileURLWithPath: sourceFile).deletingLastPathComponent()
    for _ in 0..<10 {
        let packageSwift = current.appendingPathComponent("Package.swift")
        if fm.fileExists(atPath: packageSwift.path) {
            return current
        }
        current = current.deletingLastPathComponent()
    }

    // Try 2: Walk up from current working directory (works in terminal)
    current = URL(fileURLWithPath: fm.currentDirectoryPath)
    for _ in 0..<10 {
        let packageSwift = current.appendingPathComponent("Package.swift")
        if fm.fileExists(atPath: packageSwift.path) {
            return current
        }
        current = current.deletingLastPathComponent()
    }

    return nil
}

func writeOutput(_ entries: [FallbackEntry], locale: String?) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(entries)

    let filename: String
    if let locale = locale, locale != "en" {
        filename = "emoji-fallback-\(locale).json"
    } else {
        filename = "emoji-fallback.json"
    }

    guard let packageRoot = findPackageRoot() else {
        throw NSError(domain: "CLI", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Could not find package root (Package.swift). Run from package directory."
        ])
    }

    let resourcesDir = packageRoot.appendingPathComponent("Sources/SwiftEmojiIndex/Resources")
    let fm = FileManager.default

    // Create Resources directory if it doesn't exist
    if !fm.fileExists(atPath: resourcesDir.path) {
        try fm.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
    }

    let outputURL = resourcesDir.appendingPathComponent(filename)
    try data.write(to: outputURL, options: .atomic)

    print("  ✓ Written \(entries.count) entries to \(filename)")
    print("    Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
}

// MARK: - Non-Interactive Mode

func runNonInteractive(_ options: CLIOptions) async throws {
    guard let sourceName = options.source else {
        print("Error: --source is required for non-interactive mode")
        return
    }

    print("BuildEmojiIndex (non-interactive)")
    print("──────────────────────────────────")

    switch sourceName {
    case "gemoji":
        print("Source: GitHub Gemoji")
        let gemoji = try await fetchGemoji()
        let entries = buildFromGemoji(gemoji)
        try writeOutput(entries, locale: nil)

    case "cldr":
        let locales = try await resolveLocales(options, available: commonLocales)
        print("Source: Unicode CLDR")
        print("Locales: \(locales.joined(separator: ", "))")

        for locale in locales {
            print("\n[\(locale)]")
            do {
                let annotations = try await fetchCLDR(locale: locale)
                let entries = buildFromCLDR(annotations, gemojiEntries: nil)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }

    case "blended":
        let locales = try await resolveLocales(options, available: commonLocales)
        print("Source: CLDR + Gemoji (blended)")
        print("Locales: \(locales.joined(separator: ", "))")

        print("\nFetching Gemoji for shortcodes...")
        let gemoji = try await fetchGemoji()
        print("  ✓ Loaded \(gemoji.count) Gemoji entries")

        for locale in locales {
            print("\n[\(locale)]")
            do {
                let annotations = try await fetchCLDR(locale: locale)
                let entries = buildFromCLDR(annotations, gemojiEntries: gemoji)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }

    #if os(macOS)
    case "apple":
        guard AppleEmojiDataSource.isAvailable else {
            print("Error: Apple CoreEmoji is not available on this system")
            return
        }
        let locales = try await resolveLocales(options, available: appleAvailableLocales())
        print("Source: Apple CoreEmoji")
        print("Locales: \(locales.joined(separator: ", "))")

        for locale in locales {
            print("\n[\(locale)]")
            do {
                let appleEntries = try await fetchApple(locale: locale)
                let entries = buildFromApple(appleEntries, gemojiEntries: nil)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }

    case "apple-blended":
        guard AppleEmojiDataSource.isAvailable else {
            print("Error: Apple CoreEmoji is not available on this system")
            return
        }
        let locales = try await resolveLocales(options, available: appleAvailableLocales())
        print("Source: Apple CoreEmoji + Gemoji (blended)")
        print("Locales: \(locales.joined(separator: ", "))")

        print("\nFetching Gemoji for shortcodes...")
        let gemoji = try await fetchGemoji()
        print("  ✓ Loaded \(gemoji.count) Gemoji entries")

        for locale in locales {
            print("\n[\(locale)]")
            do {
                let appleEntries = try await fetchApple(locale: locale)
                let entries = buildFromApple(appleEntries, gemojiEntries: gemoji)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }
    #endif

    default:
        print("Error: Unknown source '\(sourceName)'")
        print("Valid sources: gemoji, cldr, blended" + (isAppleAvailable() ? ", apple, apple-blended" : ""))
        return
    }

    print("\n✓ Done!")
}

func resolveLocales(_ options: CLIOptions, available: [String: String]) async throws -> [String] {
    if options.allLocales {
        return available.keys.sorted()
    }

    if let locales = options.locales {
        let valid = locales.filter { available.keys.contains($0) }
        let invalid = locales.filter { !available.keys.contains($0) }

        if !invalid.isEmpty {
            print("Warning: Unknown locales ignored: \(invalid.joined(separator: ", "))")
        }

        if valid.isEmpty {
            throw NSError(domain: "CLI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No valid locales specified"
            ])
        }

        return valid
    }

    // Default to English
    return ["en"]
}

func isAppleAvailable() -> Bool {
    #if os(macOS)
    return AppleEmojiDataSource.isAvailable
    #else
    return false
    #endif
}

// MARK: - Interactive Mode

func runInteractive() async throws {
    print("\n🎨 BuildEmojiIndex")
    print("═══════════════════════════════════════════════════")
    print("Build offline fallback emoji data for SwiftEmojiIndex")

    // Step 1: Choose source
    printHeader("Choose Data Source")

    guard let sourceChoice = promptChoice("Which source would you like to use?", options: Source.allCases.map(\.rawValue)) else {
        print("Invalid choice. Exiting.")
        return
    }

    let source = Source.allCases[sourceChoice - 1]

    switch source {
    case .gemoji:
        // Build from Gemoji only
        printHeader("Building from Gemoji")
        let gemoji = try await fetchGemoji()
        let entries = buildFromGemoji(gemoji)
        try writeOutput(entries, locale: nil)

    case .cldr:
        // Build from CLDR only (no shortcodes)
        printHeader("Select Locales")

        let selectedLocales = promptLocaleCodes("Which locales do you want to build?", available: commonLocales)

        if selectedLocales.isEmpty {
            print("No valid locales selected. Exiting.")
            return
        }

        printHeader("Building from CLDR")

        for locale in selectedLocales {
            print("\n[\(locale)]")
            do {
                let annotations = try await fetchCLDR(locale: locale)
                let entries = buildFromCLDR(annotations, gemojiEntries: nil)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }

    case .blended:
        // Build from CLDR + Gemoji (best of both)
        printHeader("Select Locales")

        let selectedLocales = promptLocaleCodes("Which locales do you want to build?", available: commonLocales)

        if selectedLocales.isEmpty {
            print("No valid locales selected. Exiting.")
            return
        }

        printHeader("Building Blended (CLDR + Gemoji)")

        // Fetch Gemoji once for enrichment
        print("\n[Fetching Gemoji for shortcodes...]")
        let gemoji = try await fetchGemoji()
        print("  ✓ Loaded \(gemoji.count) Gemoji entries")

        for locale in selectedLocales {
            print("\n[\(locale)]")
            do {
                let annotations = try await fetchCLDR(locale: locale)
                let entries = buildFromCLDR(annotations, gemojiEntries: gemoji)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }

    #if os(macOS)
    case .apple:
        // Build from Apple CoreEmoji only
        guard AppleEmojiDataSource.isAvailable else {
            print("\n✗ Apple CoreEmoji is not available on this system.")
            return
        }

        printHeader("Select Locales")

        let appleLocales = appleAvailableLocales()
        if appleLocales.isEmpty {
            print("No Apple locales available. Exiting.")
            return
        }

        let selectedLocales = promptLocaleCodes("Which locales do you want to build?", available: appleLocales)

        if selectedLocales.isEmpty {
            print("No valid locales selected. Exiting.")
            return
        }

        printHeader("Building from Apple CoreEmoji")

        for locale in selectedLocales {
            print("\n[\(locale)]")
            do {
                let appleEntries = try await fetchApple(locale: locale)
                let entries = buildFromApple(appleEntries, gemojiEntries: nil)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }

    case .appleBlended:
        // Build from Apple CoreEmoji + Gemoji
        guard AppleEmojiDataSource.isAvailable else {
            print("\n✗ Apple CoreEmoji is not available on this system.")
            return
        }

        printHeader("Select Locales")

        let appleLocales = appleAvailableLocales()
        if appleLocales.isEmpty {
            print("No Apple locales available. Exiting.")
            return
        }

        let selectedLocales = promptLocaleCodes("Which locales do you want to build?", available: appleLocales)

        if selectedLocales.isEmpty {
            print("No valid locales selected. Exiting.")
            return
        }

        printHeader("Building Blended (Apple CoreEmoji + Gemoji)")

        // Fetch Gemoji once for enrichment
        print("\n[Fetching Gemoji for shortcodes...]")
        let gemoji = try await fetchGemoji()
        print("  ✓ Loaded \(gemoji.count) Gemoji entries")

        for locale in selectedLocales {
            print("\n[\(locale)]")
            do {
                let appleEntries = try await fetchApple(locale: locale)
                let entries = buildFromApple(appleEntries, gemojiEntries: gemoji)
                try writeOutput(entries, locale: locale)
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }
    #endif
    }

    printHeader("Done!")
    print("Run your app to use the new fallback data.\n")
}

// MARK: - Entry Point

func run() async throws {
    let options = CLIOptions.parse(CommandLine.arguments)

    if options.help {
        printHelp()
        return
    }

    if options.isNonInteractive {
        try await runNonInteractive(options)
    } else {
        try await runInteractive()
    }
}

try await run()
