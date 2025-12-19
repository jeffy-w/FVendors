# 日志使用文档

[English Documentation](../en/Logging.md)

## 概述

`LoggerClient` 是 FVendors 提供的**可注入日志客户端**，遵循依赖注入原则：
- 业务代码只依赖 `LoggerClient` 抽象接口
- 生产环境使用 `LoggerClient.live`（基于 [swift-log](https://github.com/apple/swift-log) + 彩色终端输出）
- 测试环境可使用 `LoggerClient.noop` 或 `LoggerClient.collecting(storage:)`

## 快速开始

### 基本使用

```swift
import FVendors

// 生产环境
let logger = LoggerClient.live

// 记录不同级别的日志
logger.debug("调试信息")
logger.info("一般信息")
logger.warning("警告信息")
logger.error("错误信息")
logger.critical("严重错误")
```

### 在 SwiftUI 中使用（依赖注入）

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

// 定义 Environment Key
extension EnvironmentValues {
    @Entry var logger: LoggerClient = .noop
}

// 在视图中使用
struct ContentView: View {
    @Environment(\.logger) var logger
    
    var body: some View {
        Button("记录日志") {
            logger.info("按钮被点击")
        }
    }
}
```

## 日志级别

| 级别 | 方法 | 用途 |
|------|------|------|
| Debug | `logger.debug(_:)` | 调试信息，仅开发环境 |
| Info | `logger.info(_:)` | 一般信息，记录关键流程 |
| Warning | `logger.warning(_:)` | 警告信息，需注意但不影响运行 |
| Error | `logger.error(_:)` | 错误信息，影响功能但不致命 |
| Critical | `logger.critical(_:)` | 严重错误，系统级问题 |

## 测试支持

### 使用 noop（忽略日志）

```swift
import FVendors

struct MyService {
    let logger: LoggerClient
    
    func doSomething() {
        logger.info("执行操作")
    }
}

// 测试时不关心日志输出
let service = MyService(logger: .noop)
```

### 收集日志进行断言

```swift
import Testing
import FVendors

@Test func testLogging() async {
    let storage = LogStorage()
    let logger = LoggerClient.collecting(storage: storage)
    
    logger.info("测试消息")
    
    try await Task.sleep(for: .milliseconds(10))
    
    #expect(storage.logs.count == 1)
    #expect(storage.logs[0].0 == "测试消息")
    #expect(storage.logs[0].1 == .info)
}
```

## 实现细节

### 生产实现（LoggerClient.live）

- 基于 [apple/swift-log](https://github.com/apple/swift-log)
- 彩色终端输出（Debug 灰色、Info 蓝色、Warning 黄色、Error 红色、Critical 红底白字）
- 自动包含源文件位置（`文件名:行号`）与函数名
- ⚠️ `LoggingSystem.bootstrap` 只能调用一次，通过 `static let` 确保单例

### 线程安全

- `LoggerClient` 本身是 `Sendable`
- 所有方法都是 `@Sendable` 闭包，可安全跨并发域调用

## 最佳实践

1. **生产环境只初始化一次**：`LoggerClient.live` 是 `static let`，首次访问时会 bootstrap swift-log，避免重复初始化。

2. **不要在日志中泄露敏感信息**：避免记录密码、token、用户隐私数据。

3. **合理使用日志级别**：
   - 不要滥用 `debug`（会影响性能）
   - 错误应使用 `error` 或 `critical`，而非 `info`

4. **性能考虑**：日志 I/O 是同步的，高频日志会影响性能；考虑批量/异步日志（swift-log 支持自定义 handler）。

## 扩展指南

如果需要自定义日志输出（例如写入文件、上报服务器），可以：

1. 实现自定义 `LogHandler`（参考 `ColoredLogHandler`）
2. 创建新的 `LoggerClient` 静态属性

```swift
extension LoggerClient {
    public static let fileLogger: LoggerClient = {
        LoggingSystem.bootstrap(FileLogHandler.init)
        return LoggerClient(log: { message, level, file, function, line in
            // 自定义实现
        })
    }()
}
```

## 相关资源

- [apple/swift-log](https://github.com/apple/swift-log) - 底层日志库
- [LogLevel.swift](../Sources/FVendorsModels/LogLevel.swift) - 日志级别定义
- [LoggerClientTests.swift](../Tests/FVendorsClientsTests/LoggerClientTests.swift) - 测试示例
