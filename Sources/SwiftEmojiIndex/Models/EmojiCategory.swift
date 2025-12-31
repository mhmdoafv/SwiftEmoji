import Foundation

/// Standard emoji categories as defined by Unicode.
public enum EmojiCategory: String, CaseIterable, Sendable, Codable, Identifiable {
    case smileysAndEmotion = "Smileys & Emotion"
    case peopleAndBody = "People & Body"
    case animalsAndNature = "Animals & Nature"
    case foodAndDrink = "Food & Drink"
    case travelAndPlaces = "Travel & Places"
    case activities = "Activities"
    case objects = "Objects"
    case symbols = "Symbols"
    case flags = "Flags"

    /// Unique identifier for the category
    public var id: String { rawValue }

    /// Localized display name for the category
    public var displayName: String {
        rawValue
    }

    /// SF Symbol name representing this category
    public var symbolName: String {
        switch self {
        case .smileysAndEmotion:
            return "face.smiling"
        case .peopleAndBody:
            return "person"
        case .animalsAndNature:
            return "leaf"
        case .foodAndDrink:
            return "fork.knife"
        case .travelAndPlaces:
            return "car"
        case .activities:
            return "sportscourt"
        case .objects:
            return "lightbulb"
        case .symbols:
            return "heart"
        case .flags:
            return "flag"
        }
    }

    /// Creates a category from a Gemoji category string.
    /// - Parameter gemojiCategory: The category string from Gemoji data
    /// - Returns: The matching EmojiCategory, or nil if not found
    public static func from(gemojiCategory: String) -> EmojiCategory? {
        switch gemojiCategory.lowercased() {
        case "smileys & emotion", "smileys":
            return .smileysAndEmotion
        case "people & body", "people":
            return .peopleAndBody
        case "animals & nature", "nature":
            return .animalsAndNature
        case "food & drink", "food":
            return .foodAndDrink
        case "travel & places", "travel", "places":
            return .travelAndPlaces
        case "activities", "activity":
            return .activities
        case "objects", "object":
            return .objects
        case "symbols", "symbol":
            return .symbols
        case "flags", "flag":
            return .flags
        default:
            return nil
        }
    }
}
