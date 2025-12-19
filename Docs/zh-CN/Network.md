# Network 使用文档

[English Documentation](../en/Network.md)

## 概述

`NetworkClient` 是 FVendors 提供的**HTTP 网络请求客户端抽象**，支持：
- ✅ 纯 Swift 接口，不绑定具体网络库
- ✅ 自动 JSON 解码为 `Codable`
- ✅ 统一错误映射为 `AppError`
- ✅ 依赖注入（测试友好）
- ✅ 生产实现基于 [Alamofire](https://github.com/Alamofire/Alamofire)

## 快速开始

### 基本 GET 请求

```swift
import FVendors

let network = NetworkClient.live

// 构建请求
let url = URL(string: "https://api.example.com/users/123")!
let request = URLRequest(url: url)

// 发起请求（返回原始 Data）
let data = try await network.request(request)
print("收到 \(data.count) 字节")
```

### 自动解码为 Codable

```swift
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

let url = URL(string: "https://api.example.com/users/123")!
let request = URLRequest(url: url)

// 自动解码
let user = try await network.request(request, as: User.self)
print("用户名：\(user.name)")
```

### POST 请求（JSON Body）

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

let body = CreateUserRequest(name: "Alice", email: "alice@example.com")
let url = URL(string: "https://api.example.com/users")!

// 使用 APIRequestBuilder 构建 JSON 请求
let request = try APIRequestBuilder.buildJSONRequest(
    url: url,
    method: .post,
    body: body,
    headers: ["Authorization": "Bearer \(token)"]
)

let createdUser = try await network.request(request, as: User.self)
```

## 请求构建器

`APIRequestBuilder` 提供便捷方法构建常见请求：

### 构建普通请求

```swift
let request = APIRequestBuilder.buildRequest(
    url: url,
    method: .get,
    headers: ["Authorization": "Bearer token"],
    body: nil
)
```

### 构建 JSON 请求

```swift
struct LoginRequest: Codable {
    let username: String
    let password: String
}

let request = try APIRequestBuilder.buildJSONRequest(
    url: URL(string: "https://api.example.com/login")!,
    method: .post,
    body: LoginRequest(username: "alice", password: "secret")
)
// 自动设置 Content-Type: application/json
```

## HTTP 方法

```swift
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
```

使用示例：

```swift
// DELETE 请求
let request = APIRequestBuilder.buildRequest(
    url: URL(string: "https://api.example.com/users/123")!,
    method: .delete,
    headers: ["Authorization": "Bearer token"]
)

try await network.request(request)
```

## 错误处理

所有网络错误会被映射为 `AppError`：

```swift
do {
    let user = try await network.request(request, as: User.self)
    print("成功：\(user.name)")
} catch let error as AppError {
    switch error {
    case .networkError(let message):
        print("网络失败：\(message)")
    case .decodingError(let message):
        print("解码失败：\(message)")
    default:
        print("其他错误：\(error)")
    }
}
```

### 常见错误类型

| AppError | 原因 | 处理建议 |
|----------|------|----------|
| `.networkError` | 网络失败（无连接、超时、4xx/5xx） | 重试、显示错误提示 |
| `.decodingError` | JSON 解析失败 | 检查 API 版本、记录日志调试 |
| `.invalidInput` | 请求无效（错误 URL、缺少参数） | 在请求前验证输入 |

## 高级用法

### 自定义 Header

```swift
let request = APIRequestBuilder.buildRequest(
    url: url,
    method: .get,
    headers: [
        "Authorization": "Bearer \(accessToken)",
        "Accept-Language": "zh-CN",
        "User-Agent": "MyApp/1.0"
    ]
)
```

### URL 查询参数

```swift
var components = URLComponents(string: "https://api.example.com/search")!
components.queryItems = [
    URLQueryItem(name: "q", value: "swift"),
    URLQueryItem(name: "limit", value: "10")
]

let url = components.url!
let request = APIRequestBuilder.buildRequest(url: url, method: .get)
```

### PUT/PATCH 请求

```swift
struct UpdateUserRequest: Codable {
    let name: String
}

let request = try APIRequestBuilder.buildJSONRequest(
    url: URL(string: "https://api.example.com/users/123")!,
    method: .put,
    body: UpdateUserRequest(name: "Bob")
)

let updatedUser = try await network.request(request, as: User.self)
```

## 测试支持

### Mock 客户端（返回固定数据）

```swift
import Testing
import FVendors

@Test func testWithMockNetwork() async throws {
    let mockData = """
    {"id":"123","name":"Alice","email":"alice@example.com"}
    """.data(using: .utf8)!
    
    let network = NetworkClient.mock(returning: mockData)
    
    let request = URLRequest(url: URL(string: "https://api.example.com/users/123")!)
    let user = try await network.request(request, as: User.self)
    
    #expect(user.name == "Alice")
}
```

### Failing 客户端（测试错误处理）

```swift
@Test func testErrorHandling() async throws {
    let network = NetworkClient.failing(with: .networkError("连接失败"))
    
    let request = URLRequest(url: URL(string: "https://api.example.com")!)
    
    await #expect(throws: AppError.self) {
        try await network.request(request)
    }
}
```

### Noop 客户端（忽略所有请求）

```swift
let network = NetworkClient.noop
// 所有请求静默成功，返回空 Data()
```

## 实现细节

### 生产实现（基于 Alamofire）

- 使用 [Alamofire](https://github.com/Alamofire/Alamofire) 进行健壮的 HTTP 处理
- 自动重试瞬时失败
- 响应验证（状态码检查）
- 错误映射：`AFError` → `AppError`

### 线程安全

- `NetworkClient` 符合 `Sendable`
- 所有方法使用 `async/await`，可跨并发域安全调用

### 响应处理

1. **原始数据**：`request(_:) async throws -> Data`
   - 返回 HTTP body 原始数据
   - 用于非 JSON 响应（图片、文本等）

2. **解码**：`request(_:as:) async throws -> T`
   - 使用 `JSONDecoder` 解码响应
   - 解析失败时抛出 `.decodingError`

## 最佳实践

1. **集中管理 base URL**：
   ```swift
   enum API {
       static let baseURL = "https://api.example.com"
       
       static func url(path: String) -> URL {
           URL(string: baseURL + path)!
       }
   }
   
   let url = API.url(path: "/users/123")
   ```

2. **Token 管理**：
   - 不要在代码中硬编码 token
   - 使用 Keychain 或安全存储
   - 运行时注入 token

3. **错误恢复**：
   - 重试瞬时错误（超时、5xx）
   - 不要重试客户端错误（4xx）
   - 记录错误日志用于调试

4. **请求超时**：
   ```swift
   var request = URLRequest(url: url)
   request.timeoutInterval = 30  // 30 秒
   ```

5. **基于环境的 URL**：
   ```swift
   let baseURL = isProduction
       ? "https://api.example.com"
       : "https://staging.api.example.com"
   ```

## 依赖注入示例

### SwiftUI Environment

```swift
extension EnvironmentValues {
    @Entry var network: NetworkClient = .noop
}

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.network, .live)
        }
    }
}

struct ContentView: View {
    @Environment(\.network) var network
    @State private var user: User?
    
    var body: some View {
        Button("加载用户") {
            Task {
                let url = URL(string: "https://api.example.com/users/123")!
                user = try? await network.request(URLRequest(url: url), as: User.self)
            }
        }
    }
}
```

### Observable 类

```swift
@Observable
@MainActor
final class UserRepository {
    let network: NetworkClient
    
    init(network: NetworkClient = .live) {
        self.network = network
    }
    
    func fetchUser(id: String) async throws -> User {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        return try await network.request(URLRequest(url: url), as: User.self)
    }
}
```

## API 参考

### 核心接口

```swift
public struct NetworkClient: Sendable {
    /// 发起请求，返回原始 Data
    public var request: @Sendable (URLRequest) async throws -> Data
}
```

### 便捷扩展

```swift
extension NetworkClient {
    /// 发起请求，解码为 Codable 类型
    public func request<T: Codable>(
        _ request: URLRequest,
        as type: T.Type
    ) async throws -> T
}
```

### 请求构建器

```swift
public enum APIRequestBuilder {
    /// 构建标准请求
    public static func buildRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) -> URLRequest
    
    /// 构建 JSON 请求（自动编码 Codable body）
    public static func buildJSONRequest<T: Codable>(
        url: URL,
        method: HTTPMethod,
        body: T,
        headers: [String: String]? = nil
    ) throws -> URLRequest
}
```

### 测试辅助

```swift
extension NetworkClient {
    /// 总是成功返回空数据
    public static let noop: NetworkClient
    
    /// 返回固定数据
    public static func mock(returning data: Data) -> NetworkClient
    
    /// 总是失败并返回指定错误
    public static func failing(with error: AppError) -> NetworkClient
}
```

## 相关资源

- [Alamofire 文档](https://github.com/Alamofire/Alamofire) - 底层网络库
- [NetworkClient.swift](../Sources/FVendorsClients/NetworkClient.swift) - 核心接口
- [NetworkClientLive.swift](../Sources/FVendorsClientsLive/NetworkClientLive.swift) - 生产实现
- [NetworkClientTests.swift](../Tests/FVendorsClientsTests/NetworkClientTests.swift) - 测试示例
- [AppError.swift](../Sources/FVendorsModels/AppError.swift) - 错误类型定义
