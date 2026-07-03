# FVendors

[English](README.md)

一个面向现代 Apple 平台应用的轻量级 Swift 基础设施包，提供日志、网络、缓存、错误模型以及便捷聚合导入等常用能力。

## 文档

- [日志文档](Docs/zh-CN/Logging.md) | [Logging Guide](Docs/en/Logging.md)
- [缓存文档](Docs/zh-CN/Cache.md) | [Cache Guide](Docs/en/Cache.md)
- [网络文档](Docs/zh-CN/Network.md) | [Network Guide](Docs/en/Network.md)
- [0→1 App 基础设施指南](Docs/zh-CN/AppFoundation.md) | [App Foundation Guide](Docs/en/AppFoundation.md)
- [模块边界](Docs/zh-CN/Boundaries.md) | [Boundary Guide](Docs/en/Boundaries.md)

## 概览

FVendors 专注于一组小而实用的基础设施能力，方便在真实 app 中快速接入，同时避免过重的框架约束。它强调模块化 target、原生 Swift 并发、依赖注入，以及对测试友好的 client 设计。

### 适合使用 FVendors 的场景

当一个新 app 需要日志、网络、缓存、错误模型、依赖注入和测试替身等小而实用的基础设施时，适合使用 FVendors。它的目标是帮助团队尽快开始真实业务开发，而不是绑定一套重型 app 框架。

### 不适合使用 FVendors 的场景

不要把 FVendors 当作路由框架、设计系统、账号/鉴权/支付层或持久化框架。App 专属流程、模板代码和 demo chrome 应留在核心 package 之外。

### 设计理念

- **小而专注**：只提供高频、必要的基础能力。
- **Swift 6 就绪**：面向严格并发检查设计。
- **默认可测试**：核心 client 提供 `noop`、mock 或内存实现。
- **模块化**：既可以一把梭 `import FVendors`，也可以按产品精细导入。
- **类型安全**：请求、错误、缓存数据都尽量保持强类型。

## 功能特性

- **日志**：抽象日志接口，生产实现基于 `swift-log`。
- **网络**：纯 Swift 的 `NetworkClient` 抽象，live 实现基于 Alamofire。
- **缓存**：提供文件缓存 live 实现、内存缓存和过期包装器。
- **错误模型**：统一的 `AppError` 及相关 reason 枚举。
- **UI 扩展**：可选的 `FVendorsExt`，包含 SwiftUI / UIKit 扩展。

## 系统要求

- **Swift**: 6.2+
- **平台**:
  - iOS 26.0+
  - macOS 26.0+
  - watchOS 26.0+
- **依赖**:
  - Alamofire 5.10.0
  - swift-log 1.6.0+
  - CustomDump 1.3.3（测试）

## 安装

### Swift Package Manager

将 FVendors 添加到你的 `Package.swift`：

```swift
dependencies: [
    .package(url: "https://github.com/WonderJeffy/FVendors.git", from: "1.0.0")
]
```

然后按需为 target 添加产品：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FVendors", package: "FVendors"),            // 聚合导入：Models + Clients + ClientsLive
        .product(name: "FVendorsModels", package: "FVendors"),      // 共享模型与错误类型
        .product(name: "FVendorsClients", package: "FVendors"),     // 抽象 client 接口
        .product(name: "FVendorsClientsLive", package: "FVendors"), // 生产环境实现
        .product(name: "FVendorsExt", package: "FVendors")          // 可选 UI 扩展
    ]
)
```

### Xcode 项目

1. File → Add Package Dependencies
2. 输入 `https://github.com/WonderJeffy/FVendors.git`
3. 选择需要的产品

## 包结构

FVendors 当前公开 5 个 library product：

### 1. `FVendorsModels`

跨模块共享的模型类型。

**包含：**
- `AppError`
- `LogLevel`
- 相关错误原因枚举

### 2. `FVendorsClients`

面向依赖注入和测试的抽象 client 接口。

**包含：**
- `LoggerClient`
- `NetworkClient`
- `CacheClient`
- `APIRequestBuilder`

### 3. `FVendorsClientsLive`

client 接口的生产实现。

**包含：**
- `LoggerClient.live`
- `NetworkClient.live`
- `CacheClient.live`

### 4. `FVendorsExt`

可选的 SwiftUI / UIKit 扩展与包装器。使用 UI helper 时需要显式导入该产品；`FVendors` 不会重新导出 `FVendorsExt`。

```swift
import FVendorsExt

let color = Color.f.hex("#3366FF")
```

**包含：**
- `Color` 扩展
- `UIColor` 扩展
- `FWrapper`

### 5. `FVendors`

便捷聚合产品，会重新导出：

```swift
import FVendors // 重新导出 Models + Clients + ClientsLive
```

如果你想快速接入核心基础设施，优先使用 `FVendors`；UI helper 请显式导入 `FVendorsExt`；如果你需要更严格的模块边界，再按单独产品导入。

## 快速开始

### 日志

```swift
import FVendors

let logger = LoggerClient.live

logger.debug("调试消息")
logger.info("信息消息")
logger.warning("警告消息")
logger.error("错误消息")
logger.critical("严重错误")
```

### 网络

```swift
import FVendors
import Foundation

struct User: Codable {
    let id: Int
    let name: String
}

let network = NetworkClient.live.retrying(maxAttempts: 3)
let url = URL(string: "https://api.example.com/users")!
let request = URLRequest(url: url)

let users = try await network.request(request, as: [User].self)
```

### 缓存

```swift
import FVendors

struct UserPreferences: Codable {
    let theme: String
}

let cache = CacheClient.live
let preferences = UserPreferences(theme: "dark")

try await cache.write(preferences, forKey: "user-preferences")
let cached = try await cache.read(UserPreferences.self, forKey: "user-preferences")

let expiringCache = CacheClient.live.expiring(defaultTTL: .seconds(300))
try await expiringCache.write(preferences, forKey: "short-lived-preferences")
```

### 错误处理

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

## 测试

包内提供了适合测试场景的实现。

### Logger 测试

```swift
import FVendors

let storage = LogStorage()
let logger: LoggerClient = .collecting(storage: storage)

logger.info("测试消息")

await MainActor.run {
    assert(storage.logs.count == 1)
}
```

### Network 测试

```swift
import FVendorsClients
import Foundation

let network: NetworkClient = .mock { _ in
    try JSONEncoder().encode(["message": "success"])
}
```

### Cache 测试

```swift
import FVendors
import Foundation

let cache = CacheClient.inMemory()
try await cache.writeData(Data("hello".utf8), "greeting")
let data = try await cache.readData("greeting")
assert(data == Data("hello".utf8))
```

## 依赖注入

FVendors 保持简单、原生的依赖注入方式。

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
        logger.info("开始任务")
        _ = try? await network.request(URLRequest(url: URL(string: "https://api.example.com/ping")!))
    }
}
```

## App 项目接入建议

App target 默认可以从 `import FVendors` 开始，并通过初始化器注入功能需要的 client。这样业务代码可以直接使用 `LoggerClient.live`、`NetworkClient.live`、`CacheClient.live`，但不需要依赖 Alamofire、swift-log 或文件系统实现细节。

需要更严格模块边界时，再按 target 拆分产品：

- `FVendorsModels`：共享错误和值类型。
- `FVendorsClients`：抽象依赖、mock、请求和缓存辅助能力。
- `FVendorsClientsLive`：生产环境实现。
- `FVendorsExt`：可选 SwiftUI/UIKit 辅助扩展。迁移提示：使用 `Color.f`、`UIColor.f` 或 `FWrapper` 的 app target 需要显式 `import FVendorsExt`。

测试中用 `.noop`、`NetworkClient.mock(returning:)`、`NetworkClient.failing(with:)` 或 `CacheClient.inMemory()` 替换 live client。不要用 `CacheClient` 缓存密码、access token 等敏感信息；这类数据应使用 Keychain 方案。

## APIRequestBuilder

`APIRequestBuilder` 用于快速构建常见 HTTP 请求。

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

## 最佳实践

1. **通过初始化器或 app 自有环境值注入 client**。
2. **快速起步优先用 `FVendors`**，需要更细粒度控制时再拆分产品。
3. **生产环境优先使用 live 实现**。
4. **测试中使用 mock、noop 或内存缓存**。
5. **在 UI 边界附近处理 `AppError`**。
6. **合理选择日志等级**，便于排查问题。

## 示例项目

仓库包含 repo-local 的 `Demo/` Xcode app，用于展示离线基础设施路径：日志、mock 网络、cache-first 加载和 UI 状态更新。Demo app 保持在 `Package.swift` 之外，不属于 SwiftPM product surface。Demo 中的 Tomato UI 只是 demo chrome，不属于核心 FVendors 验收路径。

可参考 [SwiftUI-Template](https://github.com/jeffy-w/SwiftUI-Template.git) 获取更完整的 app 集成示例。

## Future Client 准入门槛

新增 `EnvironmentClient`、`FeatureFlagClient`、`ReachabilityClient`、`AuthTokenClient` 等 package-owned 便利 API 前，必须有 Demo 或真实 app 反复证明需要，并提供适当的 noop/mock/live 测试友好变体、聚焦测试、中英文文档和明确模块边界理由。App 自己使用 SwiftUI `EnvironmentValues` 仍然是支持的依赖注入模式。

## 许可证

[MIT License](LICENSE)

## 贡献

欢迎贡献。请提交 issue 或 pull request。

### 贡献建议

- 保持功能小而专注
- 优先使用合适的官方框架
- 保持 Swift 6 并发兼容性
- 行为变更要附带测试
- 公共用法变更要同步更新文档

## 支持

- 在 GitHub 上提交 issue
- 查看已有 issues 和 discussions
