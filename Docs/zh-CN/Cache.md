# Cache 使用文档

[English Documentation](../en/Cache.md)

## 概述

`CacheClient` 是 FVendors 提供的**本地 key-value 缓存客户端**，支持：
- ✅ 读写 `Codable` 对象
- ✅ 可选的 TTL 过期机制
- ✅ 自动后台清理过期数据
- ✅ 线程安全（actor 隔离）
- ✅ 依赖注入（测试友好）

## 快速开始

### 基本读写

```swift
import FVendors

// 生产环境：默认存储在 Caches/FVendorsCache
let cache = CacheClient.live

// 写入 Codable 对象
struct User: Codable {
    let id: String
    let name: String
}

let user = User(id: "123", name: "Alice")
try await cache.write(user, forKey: "currentUser")

// 读取
if let cachedUser = try await cache.read(User.self, forKey: "currentUser") {
    print("读取到用户：\(cachedUser.name)")
}

// 删除
try await cache.remove("currentUser")
```

### 读写原始 Data

```swift
let data = Data("Hello".utf8)
try await cache.writeData(data, "greeting")

if let retrieved = try await cache.readData("greeting") {
    print(String(data: retrieved, encoding: .utf8) ?? "")
}
```

## 过期机制

### 全局默认过期时间

```swift
// 所有写入默认 10 分钟后过期
let cache = CacheClient.live.expiring(defaultTTL: .seconds(600))

try await cache.write(user, forKey: "session")
// 10 分钟后读取会返回 nil（并自动删除）
```

### 单次写入指定 TTL

```swift
let cache = CacheClient.live

// 该条目 30 秒后过期
try await cache.write(token, forKey: "tempToken", expiresIn: .seconds(30))

// 1 小时后过期
try await cache.write(profile, forKey: "userProfile", expiresIn: .seconds(3600))
```

### 默认不过期

```swift
// 不带 expiring() / expiresIn 参数时，永久存储
let cache = CacheClient.live
try await cache.write(settings, forKey: "appSettings")  // 永不过期
```

## 自动清理机制

**CacheClient.live（文件缓存）** 会在检测到过期数据时，自动在后台调度清理任务：

- **触发时机**：读写到"带过期封装"的数据时
- **节流**：最短 30 秒调度一次（避免频繁 I/O）
- **延迟执行**：后台任务延迟 2 秒启动（不阻塞前台）
- **批量限制**：单次最多清理 200 个文件

> ⚠️ 清理是"惰性+后台"的，不保证实时删除；如需立即清理，可手动 `remove`。

## 自定义存储目录

```swift
import Foundation

// 使用自定义目录（例如 Application Support）
let customURL = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
).first!.appending(path: "MyAppCache", directoryHint: .isDirectory)

let cache = CacheClient.fileSystem(directory: customURL)
```

## 测试支持

### 内存缓存（测试）

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

### Noop 缓存（忽略所有操作）

```swift
@Test func testWithoutCache() async throws {
    let service = MyService(cache: .noop)
    // 缓存操作会被静默忽略
}
```

## 实现细节

### 文件存储（live）

- 存储路径：`FileManager.default.urls(for: .cachesDirectory, ...)/FVendorsCache/`
- Key 使用 SHA-256 哈希，避免文件名冲突
- 通过 actor 隔离（`FileCacheStore`）保证线程安全

### 过期格式

- 使用魔法前缀 `FVCache1:` 标识封装后的数据
- `CacheEnvelope` 存储：`createdAt`、`expiresAt`、`value`
- 读取时检查 `expiresAt`，过期则删除并返回 `nil`

### 后台清理逻辑

```swift
// 由读写操作触发
scheduleBackgroundPurgeIfNeeded()

// 实现
Task.detached(priority: .background) {
    try? await Task.sleep(for: .seconds(2))  // 延迟
    try await purgeExpiredFiles()            // 扫描 & 删除
}
```

## 最佳实践

1. **选择合适的过期时间**：
   - 会话数据：5-30 分钟
   - API 响应：1-5 分钟
   - 用户偏好：不过期
   - 临时 token：30-300 秒

2. **Key 命名规范**：
   - 使用反向域名记法：`com.myapp.user.profile`
   - 避免特殊字符：只用字母数字 + 点号/横杠

3. **错误处理**：
   - 缓存失败不应导致应用崩溃
   - 提供降级逻辑（如缓存未命中时从网络获取）

4. **避免敏感数据**：
   - 不要缓存明文密码/token
   - 敏感信息使用 Keychain 存储

5. **清理策略**：
   - 大多数情况依赖自动清理
   - 用户登出时使用 `removeAll()`

## API 参考

### 核心方法

```swift
public struct CacheClient: Sendable {
    /// 读取原始数据
    public var readData: @Sendable (String) async throws -> Data?
    
    /// 写入原始数据
    public var writeData: @Sendable (Data, String) async throws -> Void
    
    /// 删除单个 key
    public var remove: @Sendable (String) async throws -> Void
    
    /// 删除所有缓存数据
    public var removeAll: @Sendable () async throws -> Void
}
```

### 便捷扩展

```swift
extension CacheClient {
    /// 读取 Codable 对象
    public func read<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T?
    
    /// 写入 Codable 对象
    public func write<T: Codable>(_ value: T, forKey key: String) async throws
}
```

### 过期封装

```swift
extension CacheClient {
    /// 使用默认 TTL 封装
    public func expiring(
        defaultTTL: Duration,
        clock: any Clock<Duration> = ContinuousClock()
    ) -> CacheClient
}

extension CacheClient {
    /// 使用自定义 TTL 写入
    public func write<T: Codable>(
        _ value: T,
        forKey key: String,
        expiresIn duration: Duration
    ) async throws
}
```

## 相关资源

- [CacheClient.swift](../Sources/FVendorsClients/CacheClient.swift) - 核心接口
- [CacheClient+Expiration.swift](../Sources/FVendorsClients/CacheClient+Expiration.swift) - TTL 逻辑
- [CacheClientLive.swift](../Sources/FVendorsClientsLive/CacheClientLive.swift) - 文件实现
- [CacheClientTests.swift](../Tests/FVendorsClientsTests/CacheClientTests.swift) - 测试示例
