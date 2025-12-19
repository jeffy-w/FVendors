import FVendorsClients
import Foundation
import FVendorsModels
import Logging

extension LoggerClient {
    /// 生产环境的 Logger 实现（使用 swift-log + 彩色输出）。
    ///
    /// - Important: `LoggingSystem.bootstrap` 只能初始化一次。
    ///   这里通过 `static let` 确保只会在首次访问时 bootstrap。
    public static let live: LoggerClient = {
        // 配置彩色日志处理器（只初始化一次）
        LoggingSystem.bootstrap(ColoredLogHandler.makeFactory())

        return LoggerClient(
            log: { message, level, file, function, line in
                var logger = Logger(label: Bundle.main.bundleIdentifier ?? "com.app")

                let fileName = URL(fileURLWithPath: file).lastPathComponent
                let source = "\(fileName):\(line)"

                // 设置元数据
                logger[metadataKey: "source"] = "\(source)"
                logger[metadataKey: "function"] = "\(function)"

                // 映射日志级别
                let swiftLogLevel: Logger.Level = {
                    switch level {
                    case .debug: return .debug
                    case .info: return .info
                    case .warning: return .warning
                    case .error: return .error
                    case .critical: return .critical
                    }
                }()

                logger.log(level: swiftLogLevel, "\(message)")
            }
        )
    }()
}
