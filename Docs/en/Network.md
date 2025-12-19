# Network Guide

[中文文档](../zh-CN/Network.md)

## Overview

`NetworkClient` is FVendors' **HTTP network request client abstraction** with support for:
- ✅ Pure Swift interface, not tied to specific networking library
- ✅ Automatic JSON decoding to `Codable`
- ✅ Unified error mapping to `AppError`
- ✅ Dependency injection (testing-friendly)
- ✅ Production implementation based on [Alamofire](https://github.com/Alamofire/Alamofire)

## Quick Start

### Basic GET Request

```swift
import FVendors

let network = NetworkClient.live

// Build request
let url = URL(string: "https://api.example.com/users/123")!
let request = URLRequest(url: url)

// Make request (returns raw Data)
let data = try await network.request(request)
print("Received \(data.count) bytes")
```

### Auto-decode to Codable

```swift
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

let url = URL(string: "https://api.example.com/users/123")!
let request = URLRequest(url: url)

// Automatic decoding
let user = try await network.request(request, as: User.self)
print("Username: \(user.name)")
```

### POST Request (JSON Body)

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

let body = CreateUserRequest(name: "Alice", email: "alice@example.com")
let url = URL(string: "https://api.example.com/users")!

// Use APIRequestBuilder to build JSON request
let request = try APIRequestBuilder.buildJSONRequest(
    url: url,
    method: .post,
    body: body,
    headers: ["Authorization": "Bearer \(token)"]
)

let createdUser = try await network.request(request, as: User.self)
```

## Request Builder

`APIRequestBuilder` provides convenience methods for building common requests:

### Build Standard Request

```swift
let request = APIRequestBuilder.buildRequest(
    url: url,
    method: .get,
    headers: ["Authorization": "Bearer token"],
    body: nil
)
```

### Build JSON Request

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
// Automatically sets Content-Type: application/json
```

## HTTP Methods

```swift
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
```

Usage example:

```swift
// DELETE request
let request = APIRequestBuilder.buildRequest(
    url: URL(string: "https://api.example.com/users/123")!,
    method: .delete,
    headers: ["Authorization": "Bearer token"]
)

try await network.request(request)
```

## Error Handling

All network errors are mapped to `AppError`:

```swift
do {
    let user = try await network.request(request, as: User.self)
    print("Success: \(user.name)")
} catch let error as AppError {
    switch error {
    case .networkError(let message):
        print("Network failed: \(message)")
    case .decodingError(let message):
        print("Decode failed: \(message)")
    default:
        print("Other error: \(error)")
    }
}
```

### Common Error Types

| AppError | Cause | Handling Suggestion |
|----------|-------|---------------------|
| `.networkError` | Network failure (no connection, timeout, 4xx/5xx) | Retry, show error toast |
| `.decodingError` | JSON parsing failed | Check API version, log for debugging |
| `.invalidInput` | Invalid request (bad URL, missing params) | Validate input before request |

## Advanced Usage

### Custom Headers

```swift
let request = APIRequestBuilder.buildRequest(
    url: url,
    method: .get,
    headers: [
        "Authorization": "Bearer \(accessToken)",
        "Accept-Language": "en-US",
        "User-Agent": "MyApp/1.0"
    ]
)
```

### URL Query Parameters

```swift
var components = URLComponents(string: "https://api.example.com/search")!
components.queryItems = [
    URLQueryItem(name: "q", value: "swift"),
    URLQueryItem(name: "limit", value: "10")
]

let url = components.url!
let request = APIRequestBuilder.buildRequest(url: url, method: .get)
```

### PUT/PATCH Requests

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

## Testing Support

### Mock Client (Return Fixed Data)

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

### Failing Client (Test Error Handling)

```swift
@Test func testErrorHandling() async throws {
    let network = NetworkClient.failing(with: .networkError("Connection failed"))
    
    let request = URLRequest(url: URL(string: "https://api.example.com")!)
    
    await #expect(throws: AppError.self) {
        try await network.request(request)
    }
}
```

### Noop Client (Ignore All Requests)

```swift
let network = NetworkClient.noop
// All requests silently succeed with empty Data()
```

## Implementation Details

### Production (Alamofire-based)

- Uses [Alamofire](https://github.com/Alamofire/Alamofire) for robust HTTP handling
- Automatic retry for transient failures
- Response validation (status code checking)
- Error mapping: `AFError` → `AppError`

### Thread Safety

- `NetworkClient` is `Sendable`
- All methods use `async/await`, safe across concurrency domains

### Response Handling

1. **Raw Data**: `request(_:) async throws -> Data`
   - Returns HTTP body as-is
   - Use for non-JSON responses (images, text, etc.)

2. **Decoded**: `request(_:as:) async throws -> T`
   - Uses `JSONDecoder` to decode response
   - Throws `.decodingError` if parsing fails

## Best Practices

1. **Centralize base URL**:
   ```swift
   enum API {
       static let baseURL = "https://api.example.com"
       
       static func url(path: String) -> URL {
           URL(string: baseURL + path)!
       }
   }
   
   let url = API.url(path: "/users/123")
   ```

2. **Token management**:
   - Don't hardcode tokens in code
   - Use Keychain or secure storage
   - Inject tokens at runtime

3. **Error recovery**:
   - Retry transient errors (timeout, 5xx)
   - Don't retry client errors (4xx)
   - Log errors for debugging

4. **Request timeouts**:
   ```swift
   var request = URLRequest(url: url)
   request.timeoutInterval = 30  // 30 seconds
   ```

5. **Environment-based URLs**:
   ```swift
   let baseURL = isProduction
       ? "https://api.example.com"
       : "https://staging.api.example.com"
   ```

## Dependency Injection Example

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
        Button("Load User") {
            Task {
                let url = URL(string: "https://api.example.com/users/123")!
                user = try? await network.request(URLRequest(url: url), as: User.self)
            }
        }
    }
}
```

### Observable Class

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

## API Reference

### Core Interface

```swift
public struct NetworkClient: Sendable {
    /// Make request, return raw Data
    public var request: @Sendable (URLRequest) async throws -> Data
}
```

### Convenience Extensions

```swift
extension NetworkClient {
    /// Make request, decode to Codable type
    public func request<T: Codable>(
        _ request: URLRequest,
        as type: T.Type
    ) async throws -> T
}
```

### Request Builder

```swift
public enum APIRequestBuilder {
    /// Build standard request
    public static func buildRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) -> URLRequest
    
    /// Build JSON request (auto-encodes Codable body)
    public static func buildJSONRequest<T: Codable>(
        url: URL,
        method: HTTPMethod,
        body: T,
        headers: [String: String]? = nil
    ) throws -> URLRequest
}
```

### Test Helpers

```swift
extension NetworkClient {
    /// Always succeeds with empty data
    public static let noop: NetworkClient
    
    /// Returns fixed data
    public static func mock(returning data: Data) -> NetworkClient
    
    /// Always fails with specified error
    public static func failing(with error: AppError) -> NetworkClient
}
```

## Related Resources

- [Alamofire Documentation](https://github.com/Alamofire/Alamofire) - Underlying networking library
- [NetworkClient.swift](../Sources/FVendorsClients/NetworkClient.swift) - Core interface
- [NetworkClientLive.swift](../Sources/FVendorsClientsLive/NetworkClientLive.swift) - Production implementation
- [NetworkClientTests.swift](../Tests/FVendorsClientsTests/NetworkClientTests.swift) - Test examples
- [AppError.swift](../Sources/FVendorsModels/AppError.swift) - Error type definitions
