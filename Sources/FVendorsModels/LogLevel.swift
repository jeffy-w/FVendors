import Foundation

/// 日志级别。
///
/// 映射到 swift-log 的 `Logger.Level`：
/// - `debug` → 调试信息（仅开发环境）
/// - `info` → 一般信息
/// - `warning` → 警告（不影响运行）
/// - `error` → 错误（影响功能）
/// - `critical` → 严重错误（系统级）
public enum LogLevel: String, Sendable, CaseIterable {
    case debug
    case info
    case warning
    case error
    case critical

    /// 日志级别对应的 emoji 标记
    public var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🔥"
        }
    }
}
