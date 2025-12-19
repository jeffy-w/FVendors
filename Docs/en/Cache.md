# Cache Guide

[中文文档](../zh-CN/Cache.md)

## Overview

`CacheClient` is FVendors' **local key-value cache client** with support for:
- ✅ Read/write `Codable` objects
- ✅ Optional TTL expiration
- ✅ Automatic background cleanup of expired data
- ✅ Thread-safe (actor isolation)
- ✅ Dependency injection (testing-friendly)

## Quick Start

### Basic Read/Write

```swift
import FVendors

// Production: defaults to Caches/FVendorsCache
let cache = CacheClient.live

// Write Codable object
struct User: Codable {
    let id: String
    let name: String
}

let user = User(id: "123", name: "Alice")
try await cache.write(user, forKey: "currentUser")

// Read
if let cachedUser = try await cache.read(User.self, forKey: "currentUser") {
    print("Retrieved user: \(cachedUser.name)")
}

// Remove
try await cache.remove("currentUser")
```

### Raw Data Operations

```swift
let data = Data("Hello".utf8)
try await cache.writeData(data, "greeting")

if let retrieved = try await cache.readData("greeting") {
    print(String(data: retrieved, encoding: .utf8) ?? "")
}
```

## Expiration Mechanism

### Global Default TTL

```swift
// All writes expire after 10 minutes by default
let cache = CacheClient.live.expiring(defaultTTL: .seconds(600))

try await cache.write(user, forKey: "session")
// Reading after 10 minutes returns nil (automatically deleted)
```

### Per-Write TTL

```swift
let cache = CacheClient.live

// Expires after 30 seconds
try await cache.write(token, forKey: "tempToken", expiresIn: .seconds(30))

// Expires after 1 hour
try await cache.write(profile, forKey: "userProfile", expiresIn: .seconds(3600))
```

### No Expiration (Default)

```swift
// Without expiring() / expiresIn, data persists indefinitely
let cache = CacheClient.live
try await cache.write(settings, forKey: "appSettings")  // Never expires
```

## Automatic Cleanup

**CacheClient.live (file-based)** automatically schedules background cleanup when expired data is detected:

- **Trigger**: When reading/writing data with expiration wrapper
- **Throttling**: Minimum 30s between cleanup runs (avoids excessive I/O)
- **Delayed execution**: Background task starts after 2s delay (non-blocking)
- **Batch limit**: Maximum 200 files per cleanup run

> ⚠️ Cleanup is lazy + background; not guaranteed to be immediate. For instant removal, use `remove` manually.

## Custom Storage Directory

```swift
import Foundation

// Use custom directory (e.g., Application Support)
let customURL = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
).first!.appending(path: "MyAppCache", directoryHint: .isDirectory)

let cache = CacheClient.fileSystem(directory: customURL)
```

## Testing Support

### In-Memory Cache

```swift
import Testing
import FVendors

@Test func testCache() async throws {
    let cache = CacheClient.inMemory()
    
    try await cache.writeData(Data("test".utf8), "key")
    let data = try await cache.readData("key")
    
    #expect(data != nil)
    #expect(String(data: data!, encoding: .utf8) == "test")
}
```

### Noop Cache (Ignores All Operations)

```swift
@Test func testWithoutCache() async throws {
    let service = MyService(cache: .noop)
    // Cache operations are silently ignored
}
```

## Implementation Details

### File Storage (live)

- Storage path: `FileManager.default.urls(for: .cachesDirectory, ...)/FVendorsCache/`
- Keys hashed with SHA-256 to avoid filename collisions
- Thread-safe via actor isolation (`FileCacheStore`)

### Expiration Format

- Uses magic prefix `FVCache1:` to identify wrapped data
- `CacheEnvelope` stores: `createdAt`, `expiresAt`, `value`
- On read: checks `expiresAt`, removes if expired, returns `nil`

### Background Purge Logic

```swift
// Triggered by read/write operations
scheduleBackgroundPurgeIfNeeded()

// Implementation
Task.detached(priority: .background) {
    try? await Task.sleep(for: .seconds(2))  // Delay
    try await purgeExpiredFiles()            // Scan & delete
}
```

## Best Practices

1. **Choose appropriate expiration**:
   - Session data: 5-30 minutes
   - API responses: 1-5 minutes
   - User preferences: No expiration
   - Temporary tokens: 30-300 seconds

2. **Key naming conventions**:
   - Use reverse-domain notation: `com.myapp.user.profile`
   - Avoid special characters: stick to alphanumeric + dots/dashes

3. **Error handling**:
   - Cache failures shouldn't crash the app
   - Have fallback logic (e.g., network fetch if cache misses)

4. **Avoid sensitive data**:
   - Don't cache plaintext passwords/tokens
   - Use Keychain for sensitive information

5. **Cleanup strategy**:
   - Rely on automatic cleanup for most cases
   - Use `removeAll()` when user logs out

## API Reference

### Core Methods

```swift
public struct CacheClient: Sendable {
    /// Read raw data
    public var readData: @Sendable (String) async throws -> Data?
    
    /// Write raw data
    public var writeData: @Sendable (Data, String) async throws -> Void
    
    /// Remove single key
    public var remove: @Sendable (String) async throws -> Void
    
    /// Remove all cached data
    public var removeAll: @Sendable () async throws -> Void
}
```

### Convenience Extensions

```swift
extension CacheClient {
    /// Read Codable object
    public func read<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T?
    
    /// Write Codable object
    public func write<T: Codable>(_ value: T, forKey key: String) async throws
}
```

### Expiration Wrapper

```swift
extension CacheClient {
    /// Wrap with default TTL
    public func expiring(
        defaultTTL: Duration,
        clock: any Clock<Duration> = ContinuousClock()
    ) -> CacheClient
}

extension CacheClient {
    /// Write with custom TTL
    public func write<T: Codable>(
        _ value: T,
        forKey key: String,
        expiresIn duration: Duration
    ) async throws
}
```

## Related Resources

- [CacheClient.swift](../Sources/FVendorsClients/CacheClient.swift) - Core interface
- [CacheClient+Expiration.swift](../Sources/FVendorsClients/CacheClient+Expiration.swift) - TTL logic
- [CacheClientLive.swift](../Sources/FVendorsClientsLive/CacheClientLive.swift) - File implementation
- [CacheClientTests.swift](../Tests/FVendorsClientsTests/CacheClientTests.swift) - Test examples
