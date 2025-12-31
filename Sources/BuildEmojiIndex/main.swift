/// BuildEmojiIndex - CLI tool to build the offline fallback emoji index
///
/// This tool fetches the latest emoji data from GitHub Gemoji and converts it
/// to the EmojiRawEntry format used by SwiftEmojiIndex.
///
/// Usage:
///   swift run BuildEmojiIndex
///
/// The output is written to:
///   Sources/SwiftEmojiIndex/Resources/emoji-fallback.json

import Foundation

// MARK: - Gemoji JSON Structure

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

// MARK: - Output Format (matches EmojiRawEntry)

struct FallbackEntry: Codable {
    let character: String
    let name: String
    let category: String
    let shortcodes: [String]
    let keywords: [String]
    let supportsSkinTone: Bool
}

// MARK: - Main

func run() async throws {
    print("BuildEmojiIndex - Building offline fallback emoji index")
    print("=========================================================")

    // Fetch from GitHub Gemoji
    let url = URL(string: "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json")!
    print("Fetching from: \(url)")

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        print("Error: Failed to fetch data")
        exit(1)
    }

    print("Downloaded \(data.count) bytes")

    // Decode Gemoji entries
    let gemojiEntries = try JSONDecoder().decode([GemojiEntry].self, from: data)
    print("Parsed \(gemojiEntries.count) emojis")

    // Convert to fallback format
    let fallbackEntries = gemojiEntries.map { entry -> FallbackEntry in
        let descriptionWords = entry.description
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        let allKeywords = Set(descriptionWords + entry.aliases + entry.tags)
            .sorted()

        return FallbackEntry(
            character: entry.emoji,
            name: entry.description,
            category: entry.category,
            shortcodes: entry.aliases,
            keywords: allKeywords,
            supportsSkinTone: entry.skinTones ?? false
        )
    }

    // Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let outputData = try encoder.encode(fallbackEntries)

    // Write to Resources folder
    let outputPath = "Sources/SwiftEmojiIndex/Resources/emoji-fallback.json"
    let outputURL = URL(fileURLWithPath: outputPath)

    try outputData.write(to: outputURL)

    print("Written \(fallbackEntries.count) entries to: \(outputPath)")
    print("File size: \(outputData.count) bytes")
    print("Done!")
}

// Entry point
try await run()
