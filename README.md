# FVendors

[中文文档](README-CN.md)

A lightweight Swift infrastructure package for modern Apple-platform apps. It provides modular building blocks for logging, networking, caching, error modeling, and a convenience umbrella import for app projects.

## Documentation

- [Logging Guide](Docs/en/Logging.md) | [日志文档](Docs/zh-CN/Logging.md)
- [Cache Guide](Docs/en/Cache.md) | [缓存文档](Docs/zh-CN/Cache.md)
- [Network Guide](Docs/en/Network.md) | [网络文档](Docs/zh-CN/Network.md)
- [App Foundation Guide](Docs/en/AppFoundation.md) | [0→1 App 基础设施指南](Docs/zh-CN/AppFoundation.md)

## Overview

FVendors focuses on a small, practical set of infrastructure primitives that are useful in real apps without forcing a heavy architecture. The package favors modular targets, native Swift concurrency, dependency injection, and test-friendly client design.

### When to use FVendors

Use FVendors when a new app needs a small infrastructure foundation: logging, networking, caching, error modeling, dependency injection, and test doubles. It is designed to help app teams start real feature work quickly without committing to a heavy app framework.

### When not to use FVendors

Do not treat FVendors as a routing framework, design system, account/auth/payment layer, or persistence framework. App-specific flows, templates, and demo chrome should stay outside the core package surface.

### Philosophy

- **Minimal and Focused**: Keep the package small and composable.
- **Swift 6 Ready**: Designed for strict concurrency checking.
- **Testable by Default**: Core clients include `noop`, mock, or in-memory variants for tests.
- **Modular**: Import the umbrella package for convenience or import individual products for tighter control.
- **Type-Safe**: Use strongly typed APIs for requests, errors, and cache payloads.

## Features

- **Logging**: Structured logging abstractions with a live implementation backed by `swift-log`.
- **Networking**: A pure-Swift `NetworkClient` abstraction with an Alamofire-powered live implementation.
- **Caching**: A file-backed live cache plus in-memory and expiring wrappers for tests and app use.
- **Error Modeling**: Unified `AppError` and related reason enums for common app flows.
- **UI Extensions**: Optional SwiftUI/UIKit extensions in `FVendorsExt`.

## Requirements

- **Swift**: 6.2+
- **Platforms**:
  - iOS 26.0+
  - macOS 26.0+
  - watchOS 26.0+
- **Dependencies**:
  - Alamofire 5.10.0
  - swift-log 1.6.0+
  - CustomDump 1.3.3 (tests)

## Installation

### Swift Package Manager

Add FVendors to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/WonderJeffy/FVendors.git", from: "1.0.0")
]
```

Then add the products you need to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FVendors", package: "FVendors"),            // Umbrella import for Models + Clients + ClientsLive
        .product(name: "FVendorsModels", package: "FVendors"),      // Shared models and error types
        .product(name: "FVendorsClients", package: "FVendors"),     // Abstract client interfaces
        .product(name: "FVendorsClientsLive", package: "FVendors"), // Live client implementations
        .product(name: "FVendorsExt", package: "FVendors")          // Optional SwiftUI/UIKit extensions
    ]
)
```

### Xcode Project

1. File → Add Package Dependencies
2. Enter `https://github.com/WonderJeffy/FVendors.git`
3. Select the products you need

## Package Structure

FVendors currently exposes five library products:

### 1. `FVendorsModels`

Shared model types used across the package.

**Includes:**
- `AppError`
- `LogLevel`
- related error reason enums

### 2. `FVendorsClients`

Abstract client interfaces designed for dependency injection and testing.

**Includes:**
- `LoggerClient`
- `NetworkClient`
- `CacheClient`
- `APIRequestBuilder`

### 3. `FVendorsClientsLive`

Production implementations of the client interfaces.

**Includes:**
- `LoggerClient.live`
- `NetworkClient.live`
- `CacheClient.live`

### 4. `FVendorsExt`

Optional SwiftUI/UIKit extensions and wrappers. Import this product explicitly when using UI helpers; `FVendors` does not re-export `FVendorsExt`.

```swift
import FVendorsExt

let color = Color.f.hex("#3366FF")
```

**Includes:**
- `Color` extensions
- `UIColor` extensions
- `FWrapper`

### 5. `FVendors`

A convenience umbrella product that re-exports:

```swift
import FVendors // Re-exports Models + Clients + ClientsLive
```

Use `FVendors` when you want the fastest setup for core infrastructure in an app target. Use `FVendorsExt` explicitly for UI helpers, and use the smaller products when you want stricter module boundaries.

## Quick Start

### Logging

```swift
import FVendors

let logger: LoggerClient = .live

logger.debug("Debug information")
logger.info("General information")
logger.warning("Warning message")
logger.error("Error occurred")
logger.critical("Critical issue")
```

### Networking

```swift
import FVendors
import Foundation

struct User: Codable {
    let id: Int
    let name: String
}

let network: NetworkClient = .live
let url = URL(string: "https://api.example.com/users")!
let request = URLRequest(url: url)

let users = try await network.request(request, as: [User].self)
```

### Cache

```swift
import FVendors

struct UserPreferences: Codable {
    let theme: String
}

let cache: CacheClient = .live
let preferences = UserPreferences(theme: "dark")

try await cache.write(preferences, forKey: "user-preferences")
let cached = try await cache.read(UserPreferences.self, forKey: "user-preferences")

let expiringCache = CacheClient.live.expiring(defaultTTL: .seconds(300))
try await expiringCache.write(preferences, forKey: "short-lived-preferences")
```

### Error Handling

```swift
import FVendors
import Foundation

func loadUser(using network: NetworkClient) async {
    do {
        let request = URLRequest(url: URL(string: "https://api.example.com/users/1")!)
        let _: Data = try await network.request(request)
    } catch let error as AppError {
        print(error.userMessage)
    } catch {
        print(error.localizedDescription)
    }
}
```

## Testing

The package includes test-friendly variants for common app scenarios.

### Logger tests

```swift
import FVendors

let storage = LogStorage()
let logger: LoggerClient = .collecting(storage: storage)

logger.info("Test message")

await MainActor.run {
    assert(storage.logs.count == 1)
}
```

### Network tests

```swift
import FVendorsClients
import Foundation

let network: NetworkClient = .mock { _ in
    try JSONEncoder().encode(["message": "success"])
}
```

### Cache tests

```swift
import FVendors
import Foundation

let cache = CacheClient.inMemory()
try await cache.writeData(Data("hello".utf8), "greeting")
let data = try await cache.readData("greeting")
assert(data == Data("hello".utf8))
```

## Dependency Injection Pattern

FVendors keeps dependency injection simple and native to Swift.

```swift
import FVendors
import Foundation
import Observation

@MainActor
@Observable
final class MyViewModel {
    private let logger: LoggerClient
    private let network: NetworkClient
    private let cache: CacheClient

    init(
        logger: LoggerClient = .live,
        network: NetworkClient = .live,
        cache: CacheClient = .live
    ) {
        self.logger = logger
        self.network = network
        self.cache = cache
    }

    func performAction() async {
        logger.info("Action started")
        _ = try? await network.request(URLRequest(url: URL(string: "https://api.example.com/ping")!))
    }
}
```

## App Project Integration

For app targets, start with `import FVendors` and inject the clients your feature needs. This gives the app access to `LoggerClient.live`, `NetworkClient.live`, and `CacheClient.live` without making feature code depend on Alamofire, swift-log, or file-system details.

Use the smaller products when a target should keep stricter boundaries:

- `FVendorsModels` for shared errors and value types.
- `FVendorsClients` for abstract dependencies, mocks, and request/cache helpers.
- `FVendorsClientsLive` for production implementations.
- `FVendorsExt` for optional SwiftUI/UIKit helpers. UI helper migration note: app targets that use `Color.f`, `UIColor.f`, or `FWrapper` should add `import FVendorsExt` explicitly.

In tests, replace live clients with `.noop`, `NetworkClient.mock(returning:)`, `NetworkClient.failing(with:)`, or `CacheClient.inMemory()`. Avoid caching passwords, access tokens, or other sensitive secrets with `CacheClient`; use Keychain-backed storage for those values.

## API Request Builder

`APIRequestBuilder` helps build common HTTP requests.

```swift
import FVendorsClients
import Foundation

let url = URL(string: "https://api.example.com/login")!

let getRequest = APIRequestBuilder.buildRequest(
    url: url,
    method: .get,
    headers: ["Authorization": "Bearer token"]
)

struct LoginRequest: Codable {
    let email: String
    let password: String
}

let postRequest = try APIRequestBuilder.buildJSONRequest(
    url: url,
    method: .post,
    body: LoginRequest(email: "user@example.com", password: "secret")
)
```

## Best Practices

1. **Inject clients** through initializers or app-owned environment values.
2. **Use `FVendors` for fast app setup** and smaller products when you need tighter control.
3. **Prefer live implementations in production**.
4. **Use mocks, no-op clients, or in-memory cache in tests**.
5. **Handle `AppError` close to the UI boundary**.
6. **Use appropriate log levels** for operational clarity.

## Example Project

This repository includes a repo-local `Demo/` Xcode app that demonstrates the offline foundation path: logging, mock networking, cache-first loading, and UI state updates. The Demo app stays outside `Package.swift` and is not part of the SwiftPM product surface. Tomato UI in the Demo is demo chrome only, not a core FVendors acceptance path.

See the [SwiftUI-Template](https://github.com/jeffy-w/SwiftUI-Template.git) repository for a larger app-oriented example.

## Future Client Gate

New package-owned convenience APIs such as `EnvironmentClient`, `FeatureFlagClient`, `ReachabilityClient`, or `AuthTokenClient` require repeated Demo or real-app proof, test-friendly parity such as noop/mock/live variants where applicable, focused tests, bilingual documentation, and an explicit module-boundary rationale. App-owned SwiftUI `EnvironmentValues` usage remains a supported dependency-injection pattern.

## License

MIT License - See `LICENSE` for details.

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

### Guidelines

- Keep features small and essential.
- Prefer official Apple frameworks when practical.
- Maintain Swift 6 concurrency compatibility.
- Include tests for behavior changes.
- Update documentation when public usage changes.

## Support

- Open an issue on GitHub
- Check existing issues and discussions
