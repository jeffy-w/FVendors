# Logging Guide

[中文文档](../zh-CN/Logging.md)

## Overview

`LoggerClient` is FVendors' **injectable logging client** that follows dependency injection principles:
- Business code depends only on the `LoggerClient` abstraction
- Production uses `LoggerClient.live` (based on [swift-log](https://github.com/apple/swift-log) + colored terminal output)
- Testing can use `LoggerClient.noop` or `LoggerClient.collecting(storage:)`

## Quick Start

### Basic Usage

```swift
import FVendors

// Production
let logger = LoggerClient.live

// Log at different levels
logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.critical("Critical message")
```

### SwiftUI Integration (Dependency Injection)

```swift
import SwiftUI
import FVendors

struct MyApp: App {
    let logger = LoggerClient.live
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.logger, logger)
        }
    }
}

// Define Environment Key
extension EnvironmentValues {
    @Entry var logger: LoggerClient = .noop
}

// Use in views
struct ContentView: View {
    @Environment(\.logger) var logger
    
    var body: some View {
        Button("Log") {
            logger.info("Button tapped")
        }
    }
}
```

## Log Levels

| Level | Method | Usage |
|-------|--------|-------|
| Debug | `logger.debug(_:)` | Debug info, development only |
| Info | `logger.info(_:)` | General info, key flows |
| Warning | `logger.warning(_:)` | Warnings, attention needed but not critical |
| Error | `logger.error(_:)` | Errors affecting functionality |
| Critical | `logger.critical(_:)` | Critical errors, system-level issues |

## Testing Support

### Using noop (Ignore Logs)

```swift
import FVendors

struct MyService {
    let logger: LoggerClient
    
    func doSomething() {
        logger.info("Performing operation")
    }
}

// Testing without caring about logs
let service = MyService(logger: .noop)
```

### Collecting Logs for Assertions

```swift
import Testing
import FVendors

@Test func testLogging() async {
    let storage = LogStorage()
    let logger = LoggerClient.collecting(storage: storage)
    
    logger.info("Test message")
    
    try await Task.sleep(for: .milliseconds(10))
    
    #expect(storage.logs.count == 1)
    #expect(storage.logs[0].0 == "Test message")
    #expect(storage.logs[0].1 == .info)
}
```

## Implementation Details

### Production Implementation (LoggerClient.live)

- Based on [apple/swift-log](https://github.com/apple/swift-log)
- Colored terminal output (Debug gray, Info blue, Warning yellow, Error red, Critical red on white)
- Automatically includes source location (`filename:line`) and function name
- ⚠️ `LoggingSystem.bootstrap` can only be called once, ensured by `static let` singleton

### Thread Safety

- `LoggerClient` is `Sendable`
- All methods are `@Sendable` closures, safe to call across concurrency domains

## Best Practices

1. **Initialize once in production**: `LoggerClient.live` is a `static let`, bootstrap happens on first access.

2. **Don't leak sensitive info**: Avoid logging passwords, tokens, user privacy data.

3. **Use appropriate levels**:
   - Don't abuse `debug` (impacts performance)
   - Errors should use `error` or `critical`, not `info`

4. **Performance considerations**: Log I/O is synchronous, high-frequency logging affects performance; consider batch/async logging (swift-log supports custom handlers).

## Extension Guide

For custom log output (e.g., file writing, server reporting), you can:

1. Implement custom `LogHandler` (refer to `ColoredLogHandler`)
2. Create new `LoggerClient` static property

```swift
extension LoggerClient {
    public static let fileLogger: LoggerClient = {
        LoggingSystem.bootstrap(FileLogHandler.init)
        return LoggerClient(log: { message, level, file, function, line in
            // Custom implementation
        })
    }()
}
```

## Related Resources

- [apple/swift-log](https://github.com/apple/swift-log) - Underlying logging library
- [LogLevel.swift](../Sources/FVendorsModels/LogLevel.swift) - Log level definition
- [LoggerClientTests.swift](../Tests/FVendorsClientsTests/LoggerClientTests.swift) - Test examples
