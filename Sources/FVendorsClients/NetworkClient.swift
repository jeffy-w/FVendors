import Foundation
import FVendorsModels

/// HTTP 请求方法
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// 网络请求客户端（纯 Swift 接口，不依赖第三方库）。
///
/// 设计目标：
/// - 业务侧只依赖 `NetworkClient`，不感知 URLSession/Alamofire 等实现细节。
/// - `request(_:)` 返回原始 `Data`，解码由 `request(_:as:decoder:)` 提供。
/// - 生产环境可使用 `NetworkClient.live`（在 `FVendorsClientsLive` 中提供）。
public struct NetworkClient: Sendable {
    /// 执行网络请求，返回原始数据
    public var request: @Sendable (URLRequest) async throws -> Data

    /// 初始化网络客户端
    /// - Parameter request: 请求执行闭包
    public init(
        request: @escaping @Sendable (URLRequest) async throws -> Data
    ) {
        self.request = request
    }

    /// 执行网络请求并解码为指定类型
    /// - Parameters:
    ///   - urlRequest: URL 请求
    ///   - type: 目标类型
    ///   - decoder: JSON 解码器（默认为标准 JSONDecoder）
    /// - Returns: 解码后的对象
    public func request<T: Decodable>(
        _ urlRequest: URLRequest,
        as type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let data = try await request(urlRequest)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.networkError(.decodingFailed)
        }
    }
}

// MARK: - 辅助工具

/// API 请求构建器
public struct APIRequestBuilder {
    /// 构建 URLRequest
    /// - Parameters:
    ///   - url: 目标 URL
    ///   - method: HTTP 方法
    ///   - headers: 请求头（可选）
    ///   - body: 请求体（可选）
    /// - Returns: 构建好的 URLRequest
    public static func buildRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }

    /// 构建带 JSON 编码的 POST/PUT 请求
    /// - Parameters:
    ///   - url: 目标 URL
    ///   - method: HTTP 方法（默认 POST）
    ///   - body: 可编码的请求体
    ///   - headers: 额外的请求头（可选）
    ///   - encoder: JSON 编码器（默认为标准 JSONEncoder）
    /// - Returns: 构建好的 URLRequest
    public static func buildJSONRequest<T: Encodable>(
        url: URL,
        method: HTTPMethod = .post,
        body: T,
        headers: [String: String]? = nil,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> URLRequest {
        let data = try encoder.encode(body)
        var allHeaders = headers ?? [:]
        allHeaders["Content-Type"] = "application/json"

        return buildRequest(
            url: url,
            method: method,
            headers: allHeaders,
            body: data
        )
    }
}

// MARK: - 测试辅助

extension NetworkClient {
    /// 空实现（用于测试）
    public static let noop = NetworkClient(
        request: { _ in Data() }
    )

    /// Mock 实现（用于测试）
    /// - Parameter response: 模拟的响应闭包
    /// - Returns: NetworkClient 实例
    public static func mock(
        response: @escaping @Sendable (URLRequest) async throws -> Data
    ) -> NetworkClient {
        NetworkClient(request: response)
    }
}
