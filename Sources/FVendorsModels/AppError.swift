import Foundation

/// 统一的应用错误类型。
///
/// FVendors 中所有 Client 都会将错误映射为 `AppError`，便于统一处理：
/// - 网络错误 → `.networkError(_)`
/// - 缓存错误 → `.persistenceError(_)`
/// - 业务验证 → `.validationError(_)`
///
/// 使用示例：
/// ```swift
/// do {
///     try await cache.write(data, forKey: "key")
/// } catch let error as AppError {
///     print(error.userMessage)
/// }
/// ```
public enum AppError: Error, Sendable, Equatable {
    /// 网络错误
    case networkError(NetworkErrorReason)

    /// 数据持久化错误
    case persistenceError(PersistenceErrorReason)

    /// 业务逻辑验证错误
    case validationError(String)

    /// 未知错误
    case unknown(String)

    /// 用户友好的错误消息
    public var userMessage: String {
        switch self {
        case .networkError(let reason):
            return reason.message
        case .persistenceError(let reason):
            return reason.message
        case .validationError(let message):
            return message
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }

    /// 错误是否可恢复（可以重试）
    public var isRecoverable: Bool {
        switch self {
        case .networkError(let reason):
            return reason.isRecoverable
        case .persistenceError:
            return false
        case .validationError:
            return true
        case .unknown:
            return false
        }
    }
}

/// 网络错误原因
public enum NetworkErrorReason: Sendable, Equatable {
    /// 无网络连接
    case noConnection

    /// 请求超时
    case timeout

    /// 服务器错误（HTTP 状态码）
    case serverError(Int)

    /// JSON 解析失败
    case decodingFailed

    /// 未授权（401）
    case unauthorized

    /// 用户友好的错误消息
    public var message: String {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingFailed:
            return "Failed to parse response"
        case .unauthorized:
            return "Unauthorized access"
        }
    }

    /// 错误是否可恢复
    public var isRecoverable: Bool {
        switch self {
        case .noConnection, .timeout:
            return true
        case .serverError, .decodingFailed, .unauthorized:
            return false
        }
    }
}

/// 持久化错误原因
public enum PersistenceErrorReason: Sendable, Equatable {
    /// 保存失败
    case saveFailed

    /// 获取数据失败
    case fetchFailed

    /// 删除失败
    case deleteFailed

    /// 数据未找到
    case notFound

    /// 用户友好的错误消息
    public var message: String {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .fetchFailed:
            return "Failed to load data"
        case .deleteFailed:
            return "Failed to delete data"
        case .notFound:
            return "Data not found"
        }
    }
}

// MARK: - 错误转换扩展

extension AppError {
    /// 将任意错误转换为 AppError
    /// - Parameter error: 原始错误
    /// - Returns: AppError 实例
    public static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
