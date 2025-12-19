# FVendors

[中文文档](README-CN.md)

A lightweight Swift infrastructure package providing essential building blocks for modern iOS, macOS, and watchOS applications.

## Documentation

- [Logging Guide](Docs/en/Logging.md) | [日志文档](Docs/zh-CN/Logging.md)
- [Cache Guide](Docs/en/Cache.md) | [缓存文档](Docs/zh-CN/Cache.md)
- [Network Guide](Docs/en/Network.md) | [网络文档](Docs/zh-CN/Network.md)

## Overview

FVendors is an open-source library that offers a clean, modular approach to common app infrastructure needs. It focuses on basic functionality using official Apple frameworks and proven third-party libraries, designed for quick integration into any Swift project.

### Philosophy

- **Minimal & Focused**: Only essential infrastructure, no bloat
- **Official Extensions**: Built on Apple's frameworks (OSLog, SwiftData, Foundation)
- **Swift 6 Ready**: Full concurrency support with strict checking
- **Testable**: Mock implementations included for all clients
- **Type-Safe**: Leverages Swift's type system for safer code

## Features

- **Logging System**: Production-ready logging with OSLog
- **Network Layer**: Pure Swift networking interface with Alamofire backend
- **Data Persistence**: Generic SwiftData abstraction for CRUD operations
- **Error Handling**: Unified error types with user-friendly messages
- **Testing Utilities**: Mock implementations for all clients

## Requirements

- **Swift**: 6.2+
- **Platforms**:
  - iOS 26.0+
  - macOS 26.0+
  - watchOS 26.0+
- **Dependencies**:
  - Alamofire 5.10.0 (networking)
  - CustomDump 1.3.3 (testing)

## Installation

### Swift Package Manager

Add FVendors to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/FVendors.git", from: "1.0.0")
]
```

Then add the products you need to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FVendors", package: "FVendors"),           // UI utilities
        .product(name: "FVendorsModels", package: "FVendors"),     // Core models
        .product(name: "FVendorsClients", package: "FVendors"),    // Client interfaces
        .product(name: "FVendorsClientsLive", package: "FVendors") // Production implementations
    ]
)
```

### Xcode Project

1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the products you need

## Architecture

FVendors is organized into 4 distinct modules:

### 1. FVendorsModels

Core data models and types used across the package.

**Contents:**
- `AppError`: Unified error type with recovery hints
- `LogLevel`: Logging severity levels

### 2. FVendorsClients

Protocol-oriented client interfaces for dependency injection.

**Contents:**
- `LoggerClient`: Logging abstraction
- `NetworkClient`: HTTP networking abstraction
- `PersistenceClient<T>`: Generic SwiftData CRUD operations

### 3. FVendorsClientsLive

Production implementations of client interfaces.

**Contents:**
- `LoggerClient.live`: OSLog-based implementation
- `NetworkClient.live`: Alamofire-based implementation
- `PersistenceClient.live(modelContext:)`: SwiftData implementation

### 4. FVendors

UI utilities and extensions (currently minimal, focused on core infrastructure).

## Quick Start

### 1. Logging

```swift
import FVendorsClients
import FVendorsClientsLive

// Use in production
let logger: LoggerClient = .live

logger.debug("Debug information")
logger.info("General information")
logger.warning("Warning message")
logger.error("Error occurred")
logger.critical("Critical issue")

// Use in tests
let logger: LoggerClient = .noop
```

### 2. Networking

```swift
import FVendorsClients
import FVendorsClientsLive
import Foundation

// Setup
let networkClient: NetworkClient = .live

// Simple request
let url = URL(string: "https://api.example.com/data")!
let request = URLRequest(url: url)
let data = try await networkClient.request(request)

// Request with JSON decoding
struct User: Codable {
    let id: Int
    let name: String
}

let users = try await networkClient.request(request, as: [User].self)

// POST request with JSON body
struct CreateUser: Codable {
    let name: String
    let email: String
}

let postRequest = try APIRequestBuilder.buildJSONRequest(
    url: URL(string: "https://api.example.com/users")!,
    method: .post,
    body: CreateUser(name: "John", email: "john@example.com")
)

let createdUser = try await networkClient.request(postRequest, as: User.self)
```

### 3. Data Persistence

```swift
import FVendorsClients
import FVendorsClientsLive
import SwiftData

// Define your model
@Model
final class DiaryEntry {
    var title: String
    var content: String
    var createdAt: Date

    init(title: String, content: String, createdAt: Date = Date()) {
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

// Setup SwiftData
let modelContainer = try ModelContainer(for: DiaryEntry.self)
let modelContext = modelContainer.mainContext

// Create persistence client
let persistence: PersistenceClient<DiaryEntry> = .live(modelContext: modelContext)

// CRUD operations
// Create
let entry = DiaryEntry(title: "My Day", content: "It was great!")
try await persistence.insert(entry)
try await persistence.save()

// Read
let descriptor = FetchDescriptor<DiaryEntry>(
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)
let entries = try await persistence.fetch(descriptor)

// Delete
try await persistence.delete(entry)
try await persistence.save()
```

### 4. Error Handling

```swift
import FVendorsModels

func performNetworkRequest() async {
    do {
        let data = try await networkClient.request(request)
        // Handle success
    } catch {
        let appError = AppError.from(error)

        // Show user-friendly message
        showAlert(message: appError.userMessage)

        // Check if recoverable (can retry)
        if appError.isRecoverable {
            // Show retry button
        }

        // Handle specific error types
        switch appError {
        case .networkError(.noConnection):
            // Handle offline state
            break
        case .networkError(.unauthorized):
            // Navigate to login
            break
        default:
            break
        }
    }
}
```

## Testing

All clients include testing utilities:

### Mock Logger

```swift
import FVendorsClients

// No-op logger for tests
let logger: LoggerClient = .noop

// Collecting logger to verify log messages
let storage = LogStorage()
let logger: LoggerClient = .collecting(storage: storage)

// Perform actions
logger.info("Test message")

// Verify
await MainActor.run {
    assert(storage.logs.count == 1)
    assert(storage.logs[0].0 == "Test message")
    assert(storage.logs[0].1 == .info)
}
```

### Mock Network Client

```swift
import FVendorsClients

// No-op network client
let network: NetworkClient = .noop

// Custom mock response
let network: NetworkClient = .mock { request in
    let response = ["id": 1, "name": "Test"]
    return try JSONEncoder().encode(response)
}
```

### Mock Persistence

```swift
import FVendorsClients

// Empty storage
let persistence: PersistenceClient<DiaryEntry> = .mock()

// Pre-populated storage
let testEntries = [
    DiaryEntry(title: "Test 1", content: "Content 1"),
    DiaryEntry(title: "Test 2", content: "Content 2")
]
let persistence: PersistenceClient<DiaryEntry> = .mock(items: testEntries)
```

## Dependency Injection Pattern

FVendors uses a simple, native dependency injection approach:

```swift
import FVendorsClients
import FVendorsClientsLive

@MainActor
@Observable
final class MyViewModel {
    private let logger: LoggerClient
    private let network: NetworkClient

    init(
        logger: LoggerClient = .live,
        network: NetworkClient = .live
    ) {
        self.logger = logger
        self.network = network
    }

    func performAction() async {
        logger.info("Action started")
        // Use network client
    }
}

// Production
let viewModel = MyViewModel()

// Testing
let viewModel = MyViewModel(
    logger: .noop,
    network: .mock { _ in Data() }
)
```

## API Request Builder

Helper for building common HTTP requests:

```swift
import FVendorsClients

// Simple GET request
let getRequest = APIRequestBuilder.buildRequest(
    url: url,
    method: .get,
    headers: ["Authorization": "Bearer token"]
)

// POST with JSON
struct LoginRequest: Codable {
    let email: String
    let password: String
}

let postRequest = try APIRequestBuilder.buildJSONRequest(
    url: url,
    method: .post,
    body: LoginRequest(email: "user@example.com", password: "secret"),
    headers: ["Custom-Header": "value"]
)
```

## Advanced Usage

### Custom Error Mapping

```swift
extension AppError {
    static func fromMyAPIError(_ error: MyAPIError) -> AppError {
        switch error {
        case .invalidCredentials:
            return .validationError("Invalid email or password")
        case .accountLocked:
            return .validationError("Your account has been locked")
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
```

### Logger Categories

```swift
extension LoggerClient {
    static func category(_ name: String) -> LoggerClient {
        LoggerClient(
            log: { message, level, file, function, line in
                let logger = Logger(
                    subsystem: Bundle.main.bundleIdentifier ?? "com.app",
                    category: name
                )
                // Log implementation
            }
        )
    }
}

let networkLogger: LoggerClient = .category("Network")
let persistenceLogger: LoggerClient = .category("Persistence")
```

### Persistence with Predicates

```swift
// Fetch with filter
let predicate = #Predicate<DiaryEntry> { entry in
    entry.createdAt > Date().addingTimeInterval(-86400) // Last 24 hours
}

let descriptor = FetchDescriptor<DiaryEntry>(
    predicate: predicate,
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)

let recentEntries = try await persistence.fetch(descriptor)
```

## Best Practices

1. **Use Dependency Injection**: Always inject clients through initializers
2. **Prefer .live in Production**: Use live implementations in your app
3. **Use Mocks in Tests**: Use `.mock()` or `.noop` for testing
4. **Handle Errors Gracefully**: Use `AppError.userMessage` for UI
5. **MainActor for Persistence**: SwiftData requires `@MainActor`
6. **Log Appropriately**: Use correct log levels (debug for verbose, error for actual errors)

## Example Project

See the [SwiftUI-Template](https://github.com/yourusername/SwiftUI-Template) repository for a complete example demonstrating:

- App architecture with FVendors
- Dependency injection patterns
- Testing strategies
- Real-world usage examples

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Guidelines

- Focus on basic, essential functionality
- Use official Apple frameworks when possible
- Maintain Swift 6 concurrency compliance
- Include tests for new features
- Update documentation

## Support

For issues, questions, or suggestions:

- Open an issue on GitHub
- Check existing issues and discussions

---

**FVendors** - Fast, Focused, Foundation for Swift Apps
