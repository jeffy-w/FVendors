# 0→1 App Foundation Guide

FVendors is intended to be a lightweight infrastructure foundation for new Apple-platform apps. It helps a project start with logging, networking, caching, error modeling, dependency injection, and test doubles without adopting a full app framework.

## What FVendors is

Use FVendors when you want:

- A small set of infrastructure clients for app startup.
- Test-friendly dependencies such as `LoggerClient.noop`, `NetworkClient.mock`, and `CacheClient.inMemory()`.
- Live implementations that keep feature code independent from Alamofire, swift-log, and file-system details.
- Modular products that can be imported narrowly when a target needs tighter boundaries.

## What FVendors is not

FVendors should not become:

- A routing framework.
- A design system.
- An authentication, payment, or account framework.
- A persistence abstraction unless a future implementation plan adds and verifies one.
- A place for app-specific Demo or template code.

## Product boundaries

- `FVendorsModels`: shared errors, enums, and model-layer values.
- `FVendorsClients`: abstract clients, request builders, and test doubles.
- `FVendorsClientsLive`: production implementations.
- `FVendorsExt`: optional SwiftUI/UIKit helpers.
- `FVendors`: convenience umbrella for core infrastructure only: Models + Clients + ClientsLive.

UI helpers are intentionally not part of the core umbrella. Import them explicitly:

```swift
import FVendorsExt

let color = Color.f.hex("#3366FF")
```

## Recommended app wiring

Start at the app boundary and inject dependencies into services or view models:

```swift
import FVendors

@MainActor
final class UserViewModel {
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
}
```

In tests, replace live implementations:

```swift
let viewModel = UserViewModel(
    logger: .noop,
    network: .mock { _ in Data() },
    cache: .inMemory()
)
```

## Demo app

This repository includes a repo-local `Demo/` Xcode app that demonstrates the foundation path without adding any Demo target to `Package.swift`. The foundation proof path is offline and deterministic: it uses injected logger, network, and cache clients to demonstrate network → cache → UI state behavior.

The Tomato UI in the Demo app is demo chrome only. It is not part of the FVendors foundation acceptance criteria and should not drive core package APIs.

## Future package-owned client gate

Do not add package-owned convenience/public APIs such as `EnvironmentClient`, `FeatureFlagClient`, `ReachabilityClient`, or `AuthTokenClient` until all of the following are true:

1. Repeated Demo or real-app flows prove the need.
2. The API can ship with test-friendly parity such as noop/mock/live variants where applicable.
3. Focused tests exist.
4. English and Chinese docs are updated.
5. The module-boundary rationale is explicit.

App-owned SwiftUI `EnvironmentValues` examples remain allowed. The gate applies to new package-owned convenience APIs, not to app-side dependency injection patterns.
