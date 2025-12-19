# FVendors

[English](README.md)

一个轻量级 Swift 基础设施包，为现代 iOS、macOS 和 watchOS 应用提供基本构建块。

## 文档

- [日志文档](Docs/zh-CN/Logging.md) | [Logging Guide](Docs/en/Logging.md)
- [缓存文档](Docs/zh-CN/Cache.md) | [Cache Guide](Docs/en/Cache.md)
- [网络文档](Docs/zh-CN/Network.md) | [Network Guide](Docs/en/Network.md)

## 概述

FVendors 是一个开源库，为常见的应用基础设施需求提供简洁、模块化的解决方案。它专注于使用官方 Apple 框架和经过验证的第三方库实现基础功能，旨在快速集成到任何 Swift 项目中。

### 设计理念

- **最小化与专注**：只包含必要的基础设施，无冗余
- **官方扩展**：基于 Apple 框架构建（swift-log、Foundation）
- **Swift 6 就绪**：完整的并发支持与严格检查
- **可测试**：所有客户端都包含 Mock 实现
- **类型安全**：利用 Swift 类型系统实现更安全的代码

## 功能特性

- **日志系统**：基于 swift-log 的生产级日志
- **网络层**：纯 Swift 网络接口 + Alamofire 后端
- **缓存系统**：本地 key-value 缓存，支持 TTL 过期
- **错误处理**：统一的错误类型与用户友好的消息
- **测试工具**：所有客户端的 Mock 实现

## 系统要求

- **Swift**: 6.2+
- **平台**:
  - iOS 26.0+
  - macOS 26.0+
  - watchOS 26.0+
- **依赖**:
  - Alamofire 5.10.0（网络）
  - swift-log 1.6.0（日志）
  - CustomDump 1.3.3（测试）

## 安装

### Swift Package Manager

将 FVendors 添加到你的 `Package.swift`：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/FVendors.git", from: "1.0.0")
]
```

然后将需要的产品添加到你的 target：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FVendors", package: "FVendors"),           // 所有功能（便捷导入）
        .product(name: "FVendorsModels", package: "FVendors"),     // 核心模型
        .product(name: "FVendorsClients", package: "FVendors"),    // 客户端接口
        .product(name: "FVendorsClientsLive", package: "FVendors"), // 生产实现
        .product(name: "FVendorsExt", package: "FVendors")         // UI 扩展
    ]
)
```

### Xcode 项目

1. File → Add Package Dependencies
2. 输入仓库 URL
3. 选择需要的产品

## 架构

FVendors 组织为 5 个独立模块：

### 1. FVendorsModels

跨包使用的核心数据模型和类型。

**内容：**
- `AppError`：统一错误类型，带恢复提示
- `LogLevel`：日志严重级别

### 2. FVendorsClients

用于依赖注入的面向协议的客户端接口。

**内容：**
- `LoggerClient`：日志抽象
- `NetworkClient`：HTTP 网络抽象
- `CacheClient`：本地缓存抽象

### 3. FVendorsClientsLive

客户端接口的生产实现。

**内容：**
- `LoggerClient.live`：基于 swift-log 的实现
- `NetworkClient.live`：基于 Alamofire 的实现
- `CacheClient.live`：基于文件系统的实现

### 4. FVendorsExt

SwiftUI 和 UIKit 的 UI 扩展。

**内容：**
- `Color` 扩展
- `UIColor` 扩展
- 通用包装器（`FWrapper`）

### 5. FVendors

便捷的统一导入模块，重新导出所有客户端。

```swift
import FVendors  // 导入所有 Clients + ClientsLive + Models
```

## 快速开始

### 日志

```swift
import FVendors

// 生产环境
let logger = LoggerClient.live

logger.debug("调试消息")
logger.info("信息消息")
logger.warning("警告消息")
logger.error("错误消息")
```

### 缓存

```swift
import FVendors

let cache = CacheClient.live

// 写入 Codable 对象
struct User: Codable {
    let id: String
    let name: String
}

let user = User(id: "123", name: "Alice")
try await cache.write(user, forKey: "currentUser")

// 读取
if let cached = try await cache.read(User.self, forKey: "currentUser") {
    print("缓存的用户：\(cached.name)")
}

// 带过期时间
try await cache.write(user, forKey: "session", expiresIn: .seconds(300))
```

### 网络

```swift
import FVendors

let network = NetworkClient.live

// 简单 GET 请求
let url = URL(string: "https://api.example.com/users")!
let request = URLRequest(url: url)
let users = try await network.request(request, as: [User].self)

// POST 带 JSON body
let createRequest = try APIRequestBuilder.buildJSONRequest(
    url: url,
    method: .post,
    body: User(id: "456", name: "Bob")
)
let created = try await network.request(createRequest, as: User.self)
```

## 测试

所有客户端都包含测试友好的实现：

```swift
import Testing
import FVendors

@Test func testLogging() async {
    let storage = LogStorage()
    let logger = LoggerClient.collecting(storage: storage)
    
    logger.info("测试消息")
    
    try await Task.sleep(for: .milliseconds(10))
    #expect(storage.logs.count == 1)
}

@Test func testCache() async throws {
    let cache = CacheClient.inMemory()
    
    try await cache.writeData(Data("test".utf8), "key")
    let data = try await cache.readData("key")
    
    #expect(data == Data("test".utf8))
}

@Test func testNetwork() async throws {
    let mock = NetworkClient.mock { _ in
        try JSONEncoder().encode(["message": "success"])
    }
    
    let response = try await mock.request(
        URLRequest(url: URL(string: "https://example.com")!),
        as: [String: String].self
    )
    
    #expect(response["message"] == "success")
}
```

## 依赖注入

所有客户端都设计为依赖注入：

```swift
struct MyService {
    let logger: LoggerClient
    let network: NetworkClient
    let cache: CacheClient
    
    func performTask() async throws {
        logger.info("开始任务")
        
        let data = try await network.request(...)
        try await cache.write(data, forKey: "result")
        
        logger.info("任务完成")
    }
}

// 生产环境
let service = MyService(
    logger: .live,
    network: .live,
    cache: .live
)

// 测试环境
let testService = MyService(
    logger: .noop,
    network: .mock { _ in Data() },
    cache: .inMemory()
)
```

## 错误处理

统一的 `AppError` 类型便于处理：

```swift
do {
    try await network.request(...)
} catch let error as AppError {
    switch error {
    case .networkError(.noConnection):
        print("无网络连接")
    case .networkError(.timeout):
        print("请求超时")
    case .persistenceError(.saveFailed):
        print("保存失败")
    default:
        print("错误：\(error.userMessage)")
    }
}
```

## 贡献

欢迎贡献！请提交 issue 或 pull request。

## 许可证

[MIT License](LICENSE)

## 相关资源

- [apple/swift-log](https://github.com/apple/swift-log) - 日志框架
- [Alamofire/Alamofire](https://github.com/Alamofire/Alamofire) - HTTP 网络库
- [pointfreeco/swift-custom-dump](https://github.com/pointfreeco/swift-custom-dump) - 测试工具
