import Foundation

/// Errors that can occur when working with the emoji index.
public enum EmojiIndexError: Error, LocalizedError, Sendable {
    /// Network is unavailable or the request failed to connect.
    case networkUnavailable(underlying: Error)

    /// The server returned an invalid HTTP response.
    case invalidResponse(statusCode: Int)

    /// Failed to decode the emoji data.
    case decodingFailed(underlying: Error)

    /// Failed to read from the cache.
    case cacheReadFailed(underlying: Error)

    /// Failed to write to the cache.
    case cacheWriteFailed(underlying: Error)

    /// No emoji data is available (no network, no cache, no fallback).
    case noDataAvailable

    /// The data source returned empty data.
    case emptyData

    /// An invalid URL was provided.
    case invalidURL(String)

    /// The data source is not available on this platform.
    case sourceUnavailable(reason: String)

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable(let error):
            return "Network unavailable: \(error.localizedDescription)"
        case .invalidResponse(let statusCode):
            return "Invalid server response (HTTP \(statusCode))"
        case .decodingFailed(let error):
            return "Failed to decode emoji data: \(error.localizedDescription)"
        case .cacheReadFailed(let error):
            return "Failed to read cache: \(error.localizedDescription)"
        case .cacheWriteFailed(let error):
            return "Failed to write cache: \(error.localizedDescription)"
        case .noDataAvailable:
            return "No emoji data available"
        case .emptyData:
            return "Data source returned empty data"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .sourceUnavailable(let reason):
            return "Data source unavailable: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .invalidResponse:
            return "The emoji data server may be temporarily unavailable. Try again later."
        case .decodingFailed:
            return "The emoji data format may have changed. Try updating the package."
        case .cacheReadFailed, .cacheWriteFailed:
            return "Try clearing the app's cache and restarting."
        case .noDataAvailable:
            return "Connect to the internet to download emoji data."
        case .emptyData:
            return "The data source may be temporarily unavailable. Try again later."
        case .invalidURL:
            return "Check the data source URL configuration."
        case .sourceUnavailable:
            return "This data source is not available on this platform."
        }
    }
}
