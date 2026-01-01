/// BuildEmojiIndex - CLI to build offline fallback emoji indexes
///
/// Usage:
///   swift run BuildEmojiIndex                    # Interactive mode
///   swift run BuildEmojiIndex --help             # Show help
///   swift run BuildEmojiIndex --source blended --locales en,ja,ko
///   swift run BuildEmojiIndex --source blended --all-locales
///
/// Sources:
///   gemoji   - GitHub Gemoji (English only, with shortcodes)
///   cldr     - Unicode CLDR (localized, no shortcodes)
///   blended  - CLDR + Gemoji (localized with shortcodes) [recommended]
///   apple    - Apple CoreEmoji (macOS only)
///   apple-blended - Apple + Gemoji (macOS only)

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
    var sources = """
      gemoji        GitHub Gemoji (English only, with shortcodes)
      cldr          Unicode CLDR (localized, no shortcodes)
      blended       CLDR + Gemoji (localized with shortcodes) [recommended]
    """

    #if os(macOS)
    sources += """

      apple         Apple CoreEmoji (macOS only)
      apple-blended Apple CoreEmoji + Gemoji (macOS only)
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

    SOURCES:
    \(sources)

    EXAMPLES:
      # Interactive mode
      swift run BuildEmojiIndex

      # Build English fallback from Gemoji
      swift run BuildEmojiIndex --source gemoji

      # Build specific locales with CLDR + Gemoji
      swift run BuildEmojiIndex --source blended --locales en,ja,ko,zh

      # Build all available CLDR locales
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
    case gemoji = "GitHub Gemoji (English, with shortcodes)"
    case cldr = "Unicode CLDR (100+ languages)"
    case blended = "CLDR + Gemoji (localized names with shortcodes)"
    #if os(macOS)
    case apple = "Apple CoreEmoji (macOS, highest quality localization)"
    case appleBlended = "Apple CoreEmoji + Gemoji (macOS, localized with shortcodes)"
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
    // Index gemoji by character for enrichment (categories, shortcodes, etc.)
    var gemojiByChar: [String: GemojiEntry] = [:]
    if let gemoji = gemojiEntries {
        for entry in gemoji {
            gemojiByChar[entry.emoji] = entry
        }
    }

    return entries.map { entry in
        let gemoji = gemojiByChar[entry.character]

        return FallbackEntry(
            character: entry.character,
            name: entry.name,
            category: gemoji?.category ?? entry.category,  // Get category from Gemoji
            shortcodes: gemoji?.aliases ?? entry.shortcodes,
            keywords: Array(Set(entry.keywords + (gemoji?.tags ?? []))).sorted(),
            supportsSkinTone: gemoji?.skinTones ?? entry.supportsSkinTone
        )
    }
}
#endif

func buildFromCLDR(_ annotations: [String: CLDRAnnotation], gemojiEntries: [GemojiEntry]?) -> [FallbackEntry] {
    // Index gemoji by character for enrichment
    var gemojiByChar: [String: GemojiEntry] = [:]
    if let gemoji = gemojiEntries {
        for entry in gemoji {
            gemojiByChar[entry.emoji] = entry
        }
    }

    let skinToneModifiers: Set<Unicode.Scalar> = [
        "\u{1F3FB}", "\u{1F3FC}", "\u{1F3FD}", "\u{1F3FE}", "\u{1F3FF}"
    ]

    var entries: [FallbackEntry] = []

    for (character, annotation) in annotations {
        // Skip skin tone variants
        if character.unicodeScalars.contains(where: { skinToneModifiers.contains($0) }) {
            continue
        }

        let name = annotation.tts?.first ?? character
        let keywords = annotation.default ?? []

        // Enrich with Gemoji data if available
        let gemoji = gemojiByChar[character]

        entries.append(FallbackEntry(
            character: character,
            name: name,
            category: gemoji?.category ?? "Unknown",
            shortcodes: gemoji?.aliases ?? [],
            keywords: Array(Set(keywords + (gemoji?.tags ?? []))).sorted(),
            supportsSkinTone: gemoji?.skinTones ?? false
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
