import Foundation
import FVendorsModels

/// Logger metadata attached to one log event.
public typealias LoggerMetadata = [String: String]

/// A log record captured by test loggers.
public struct LogRecord: Sendable, Equatable {
    public let message: String
    public let level: LogLevel
    public let metadata: LoggerMetadata
    public let file: String
    public let function: String
    public let line: Int

    public init(
        message: String,
        level: LogLevel,
        metadata: LoggerMetadata = [:],
        file: String,
        function: String,
        line: Int
    ) {
        self.message = message
        self.level = level
        self.metadata = metadata
        self.file = file
        self.function = function
        self.line = line
    }
}

/// Logger 客户端抽象接口。
///
/// 这是一个可注入的依赖接口：
/// - 业务侧只依赖 `LoggerClient`，不直接依赖具体日志库。
/// - 生产环境可使用 `LoggerClient.live`（在 `FVendorsClientsLive` 中提供）。
public struct LoggerClient: Sendable {
    /// 记录日志的核心方法，保持不带 metadata 的兼容接口。
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别
    ///   - file: 文件路径
    ///   - function: 函数名
    ///   - line: 行号
    public var log: @Sendable (String, LogLevel, String, String, Int) -> Void

    /// 记录带 metadata 的日志。
    public var logWithMetadata: @Sendable (String, LogLevel, LoggerMetadata, String, String, Int) -> Void

    public init(
        log: @escaping @Sendable (String, LogLevel, String, String, Int) -> Void
    ) {
        self.log = log
        self.logWithMetadata = { message, level, _, file, function, line in
            log(message, level, file, function, line)
        }
    }

    public init(
        logWithMetadata: @escaping @Sendable (String, LogLevel, LoggerMetadata, String, String, Int) -> Void
    ) {
        self.logWithMetadata = logWithMetadata
        self.log = { message, level, file, function, line in
            logWithMetadata(message, level, [:], file, function, line)
        }
    }

    // MARK: - 便捷方法

    /// 记录调试信息
    public func debug(
        _ message: String,
        metadata: LoggerMetadata = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logWithMetadata(message, .debug, metadata, file, function, line)
    }

    /// 记录一般信息
    public func info(
        _ message: String,
        metadata: LoggerMetadata = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logWithMetadata(message, .info, metadata, file, function, line)
    }

    /// 记录警告信息
    public func warning(
        _ message: String,
        metadata: LoggerMetadata = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logWithMetadata(message, .warning, metadata, file, function, line)
    }

    /// 记录错误信息
    public func error(
        _ message: String,
        metadata: LoggerMetadata = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logWithMetadata(message, .error, metadata, file, function, line)
    }

    /// 记录严重错误信息
    public func critical(
        _ message: String,
        metadata: LoggerMetadata = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logWithMetadata(message, .critical, metadata, file, function, line)
    }
}

// MARK: - 测试辅助

/// 日志存储（用于测试）
@MainActor
public final class LogStorage: Sendable {
    public var records: [LogRecord] = []

    public var logs: [(String, LogLevel)] {
        get {
            records.map { ($0.message, $0.level) }
        }
        set {
            records = newValue.map { message, level in
                LogRecord(
                    message: message,
                    level: level,
                    file: "",
                    function: "",
                    line: 0
                )
            }
        }
    }

    public init() {}
}

extension LoggerClient {
    /// 空操作 Logger（用于不需要日志的场景）
    public static let noop = LoggerClient(
        logWithMetadata: { _, _, _, _, _, _ in }
    )

    /// 收集日志的 Logger（用于测试）
    /// - Parameter storage: 用于收集日志的存储对象
    /// - Returns: LoggerClient 实例
    public static func collecting(storage: LogStorage) -> LoggerClient {
        LoggerClient(
            logWithMetadata: { message, level, metadata, file, function, line in
                Task { @MainActor in
                    storage.records.append(
                        LogRecord(
                            message: message,
                            level: level,
                            metadata: metadata,
                            file: file,
                            function: function,
                            line: line
                        )
                    )
                }
            }
        )
    }
}
