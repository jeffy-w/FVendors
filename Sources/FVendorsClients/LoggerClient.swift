import Foundation
import FVendorsModels

/// Logger 客户端抽象接口。
///
/// 这是一个可注入的依赖接口：
/// - 业务侧只依赖 `LoggerClient`，不直接依赖具体日志库。
/// - 生产环境可使用 `LoggerClient.live`（在 `FVendorsClientsLive` 中提供）。
public struct LoggerClient: Sendable {
    /// 记录日志的核心方法
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别
    ///   - file: 文件路径
    ///   - function: 函数名
    ///   - line: 行号
    public var log: @Sendable (String, LogLevel, String, String, Int) -> Void

    public init(
        log: @escaping @Sendable (String, LogLevel, String, String, Int) -> Void
    ) {
        self.log = log
    }

    // MARK: - 便捷方法

    /// 记录调试信息
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, .debug, file, function, line)
    }

    /// 记录一般信息
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, .info, file, function, line)
    }

    /// 记录警告信息
    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, .warning, file, function, line)
    }

    /// 记录错误信息
    public func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, .error, file, function, line)
    }

    /// 记录严重错误信息
    public func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, .critical, file, function, line)
    }
}

// MARK: - 测试辅助

/// 日志存储（用于测试）
@MainActor
public final class LogStorage: Sendable {
    public var logs: [(String, LogLevel)] = []

    public init() {}
}

extension LoggerClient {
    /// 空操作 Logger（用于不需要日志的场景）
    public static let noop = LoggerClient(
        log: { _, _, _, _, _ in }
    )

    /// 收集日志的 Logger（用于测试）
    /// - Parameter storage: 用于收集日志的存储对象
    /// - Returns: LoggerClient 实例
    public static func collecting(storage: LogStorage) -> LoggerClient {
        LoggerClient(
            log: { message, level, _, _, _ in
                Task { @MainActor in
                    storage.logs.append((message, level))
                }
            }
        )
    }
}
