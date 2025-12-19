import Alamofire
import FVendorsClients
import Foundation
import FVendorsModels

extension NetworkClient {
    /// 生产环境的网络客户端实现（使用 Alamofire）。
    ///
    /// - Note: 该实现会：
    ///   - 自动 `validate()`，将非 2xx 视为失败
    ///   - 将 Alamofire/URL 错误映射为 `AppError`
    public static let live = NetworkClient(
        request: { urlRequest in
            try await withCheckedThrowingContinuation { continuation in
                AF.request(urlRequest)
                    .validate()
                    .responseData { response in
                        switch response.result {
                        case .success(let data):
                            continuation.resume(returning: data)
                        case .failure(let error):
                            let appError = mapAlamofireError(error, response: response.response)
                            continuation.resume(throwing: appError)
                        }
                    }
            }
        }
    )
}

// MARK: - 错误映射

/// 将 Alamofire 错误映射为 AppError
/// - Parameters:
///   - error: Alamofire 错误
///   - response: HTTP 响应
/// - Returns: 映射后的 AppError
private func mapAlamofireError(_ error: AFError, response: HTTPURLResponse?) -> AppError {
    // 处理 HTTP 状态码错误
    if let statusCode = response?.statusCode {
        switch statusCode {
        case 401:
            return .networkError(.unauthorized)
        case 400..<500:
            return .networkError(.serverError(statusCode))
        case 500..<600:
            return .networkError(.serverError(statusCode))
        default:
            break
        }
    }

    // 处理底层网络错误
    if let underlyingError = error.underlyingError as? URLError {
        switch underlyingError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError(.noConnection)
        case .timedOut:
            return .networkError(.timeout)
        default:
            return .networkError(.serverError(underlyingError.errorCode))
        }
    }

    // 其他错误
    return .unknown(error.localizedDescription)
}
