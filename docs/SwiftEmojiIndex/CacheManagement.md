# SwiftEmojiIndex - Cache Management

Detailed control over cached emoji data.

## Quick Start

```swift
let cache = DiskCache.shared
try await cache.clearAll()
```

## Inspecting Cache

```swift
let cache = DiskCache.shared

// List all cached entries
let entries = await cache.listEntries()
for entry in entries {
    print("\(entry.sourceIdentifier): \(entry.emojiCount) emoji, \(entry.fileSize) bytes")
    print("  Last updated: \(entry.lastUpdated)")
}

// Total cache size
let totalBytes = await cache.totalSize()

// Check if specific cache is expired
let isOld = await cache.isExpired(for: "gemoji", maxAge: 7 * 24 * 60 * 60) // 7 days
```

## Clearing Cache

```swift
// Clear expired entries only
try await cache.clearExpired(maxAge: 7 * 24 * 60 * 60)

// Clear specific source
try await cache.clear(for: "gemoji")

// Clear everything
try await cache.clearAll()
```

## Custom Cache Implementation

```swift
struct MyCache: EmojiCache {
    func load(for sourceIdentifier: String) async throws -> (entries: [EmojiRawEntry], lastUpdated: Date)? { }
    func save(_ entries: [EmojiRawEntry], for sourceIdentifier: String) async throws { }
    func clear(for sourceIdentifier: String) async throws { }
    func clearAll() async throws { }
}

let provider = EmojiIndexProvider(source: GemojiDataSource.shared, cache: MyCache())
```

## Notes

- Cache location: `~/Library/Caches/[bundleID]/SwiftEmojiIndex/[sourceId].json`
- Default refresh interval: 24 hours
- Cache is shared across all `EmojiIndexProvider` instances using the same source identifier
