import Foundation

/// Skin tone modifiers for emoji that support them.
public enum SkinTone: String, CaseIterable, Sendable, Codable, Identifiable {
    case none
    case light
    case mediumLight
    case medium
    case mediumDark
    case dark

    /// Unique identifier
    public var id: String { rawValue }

    /// The Unicode skin tone modifier character.
    /// Returns an empty string for `.none`.
    public var modifier: String {
        switch self {
        case .none:
            return ""
        case .light:
            return "\u{1F3FB}" // 🏻
        case .mediumLight:
            return "\u{1F3FC}" // 🏼
        case .medium:
            return "\u{1F3FD}" // 🏽
        case .mediumDark:
            return "\u{1F3FE}" // 🏾
        case .dark:
            return "\u{1F3FF}" // 🏿
        }
    }

    /// Human-readable display name for the skin tone.
    public var displayName: String {
        switch self {
        case .none:
            return "Default"
        case .light:
            return "Light"
        case .mediumLight:
            return "Medium-Light"
        case .medium:
            return "Medium"
        case .mediumDark:
            return "Medium-Dark"
        case .dark:
            return "Dark"
        }
    }

    /// Example emoji showing this skin tone (raised hand).
    public var example: String {
        "✋" + modifier
    }
}
