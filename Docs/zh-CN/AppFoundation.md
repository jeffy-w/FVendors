# 0→1 App 基础设施指南

FVendors 的定位是新 Apple 平台 app 的轻量基础设施底座。它帮助项目从第一天就具备日志、网络、缓存、错误建模、依赖注入和测试替身，而不是强制采用完整 app 框架。

## FVendors 是什么

适合在这些场景使用 FVendors：

- 新项目需要一组小而实用的基础设施 client。
- 测试中需要 `LoggerClient.noop`、`NetworkClient.mock`、`CacheClient.inMemory()` 等替身。
- 业务代码不希望直接依赖 Alamofire、swift-log 或文件系统实现细节。
- 不同 target 需要按模块精细导入。

## FVendors 不是什么

FVendors 不应该变成：

- 路由框架。
- 设计系统。
- 账号、支付或鉴权业务框架。
- 未经独立规划和验证的持久化抽象。
- 存放 app 专属 Demo 或模板代码的地方。

## 产品边界

- `FVendorsModels`：共享错误、枚举和值类型。
- `FVendorsClients`：抽象 client、请求构建和测试替身。
- `FVendorsClientsLive`：生产环境实现。
- `FVendorsExt`：可选 SwiftUI/UIKit 辅助扩展。
- `FVendors`：核心基础设施聚合导入，只包含 Models + Clients + ClientsLive。

UI helper 不属于核心 umbrella。需要显式导入：

```swift
import FVendorsExt

let color = Color.f.hex("#3366FF")
```

## 推荐 app 接线方式

在 app 边界创建 app 自己拥有的依赖容器，再把具体 client 注入 service 或
view model。这个容器应保留在 app target 中，不放进 FVendors：

```swift
import FVendors

struct AppDependencies: Sendable {
    let logger: LoggerClient
    let network: NetworkClient
    let cache: CacheClient

    static let live = AppDependencies(
        logger: .live,
        network: NetworkClient.live.retrying(maxAttempts: 3),
        cache: .live
    )
}
```

SwiftUI app 可以在 app target 里用 `EnvironmentValues` 暴露这个 app-owned
container：

```swift
import SwiftUI

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.live
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
```

View model 仍然应该通过初始化器接收具体 FVendors clients：

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

测试中替换 live 实现：

```swift
let viewModel = UserViewModel(
    logger: .noop,
    network: .mock { _ in Data() },
    cache: .inMemory()
)
```

## Demo App

仓库包含一个 repo-local 的 `Demo/` Xcode app，用来展示基础设施接入路径；它不会作为 target/product 加入 `Package.swift`。Demo 的基础证明路径是离线且确定性的：通过注入 logger、network、cache 展示 network → cache → UI state 行为。

Demo app 现在端到端证明了 app-owned 接线模式：

- `AppDependencies` 定义在 `Demo/` 内，而不是 package 内。
- `DemoApp` 创建单一依赖容器，并通过 SwiftUI `EnvironmentValues` 注入。
- `DemoViewModel` 通过容器接收 `LoggerClient`、`NetworkClient` 和 `CacheClient`。
- Demo tests 验证 logger metadata、mock network 数据和 in-memory cache 可以协同工作。
- UI helpers 仍然需要显式 `import FVendorsExt`。

Demo 中的 Tomato UI 只是 demo chrome，不属于 FVendors 基础设施验收标准，也不应驱动核心 package API。

## 未来 package-owned client 准入门槛

不要直接新增 `EnvironmentClient`、`FeatureFlagClient`、`ReachabilityClient`、`AuthTokenClient` 等 package-owned convenience/public API，除非同时满足：

1. Demo 或真实 app flow 反复证明需要。
2. API 能提供适当的 noop/mock/live 等测试友好变体。
3. 有聚焦测试。
4. 中英文文档已更新。
5. 模块边界理由明确。

App 自己定义和使用 SwiftUI `EnvironmentValues` 仍然允许。这个门槛限制的是新的 package-owned 便利 API，不限制 app 侧依赖注入模式。
