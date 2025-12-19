import Darwin
import Foundation
import Logging

/// 带颜色的日志处理器，支持 Xcode 和 VSCode 控制台。
///
/// 特性：
/// - 自动检测环境：Xcode 禁用 ANSI，VSCode/Terminal 启用
/// - 可通过 `FVENDORS_LOG_ANSI=1` 环境变量强制启用
/// - 遵循 `NO_COLOR` 约定
///
/// - Note: 仅用于 `FVendorsClientsLive` 内部，外部请使用 `LoggerClient.live`。
internal struct ColoredLogHandler: LogHandler {
    var logLevel: Logger.Level = .debug
    var metadata: Logger.Metadata = [:]

    private let label: String

    private static let supportsANSI: Bool = {
        let env = ProcessInfo.processInfo.environment

        // Manual override.
        if let forced = env["FVENDORS_LOG_ANSI"] {
            switch forced.trimmingCharacters(in: .whitespacesAndNewlines) {
            case "1", "true", "TRUE", "yes", "YES":
                return true
            case "0", "false", "FALSE", "no", "NO":
                return false
            default:
                break
            }
        }

        // Respect the community convention.
        if env["NO_COLOR"] != nil { return false }

        // Xcode console typically prints ANSI sequences as raw text.
        // Detect Xcode and disable ANSI to avoid noisy output.
        if env["XCODE_VERSION_ACTUAL"] != nil { return false }
        if env["XCODE_PRODUCT_BUILD_VERSION"] != nil { return false }
        if env["XCODE_RUNNING_FOR_PREVIEWS"] != nil { return false }
        if env["OS_ACTIVITY_DT_MODE"] != nil { return false }

        // VSCode's debug console/terminal often supports ANSI even when not a TTY.
        if env["TERM_PROGRAM"]?.lowercased() == "vscode" { return true }
        if env["VSCODE_PID"] != nil { return true }

        // Fallback: enable only when attached to a TTY and TERM isn't dumb.
        guard isatty(STDERR_FILENO) != 0 else { return false }
        let term = env["TERM"]?.lowercased()
        if term == nil || term == "dumb" { return false }
        return true
    }()

    init(label: String) {
        self.label = label
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let timestamp = formatTimestamp(Date())
        let levelString = formatLevel(level)
        let metadataString = formatMetadata(metadata)

        var components: [String] = [timestamp, levelString]

        if !metadataString.isEmpty {
            components.append(metadataString)
        }

        components.append("\(message)")

        let output = components.joined(separator: " ")
        emit(output)
    }

    private func emit(_ output: String) {
        // Prefer stderr so that tools like xcodebuild/SweetPad are more likely to capture output.
        let line = output + "\n"
        if let data = line.data(using: .utf8) {
            try? FileHandle.standardError.write(contentsOf: data)
        } else {
            fputs(line, stderr)
        }
    }

    // MARK: - Formatting

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: date)
        return colorize(timestamp, color: .gray)
    }

    private func formatLevel(_ level: Logger.Level) -> String {
        let (emoji, color, text) = levelInfo(level)
        return "\(emoji) \(colorize(text.uppercased().padding(toLength: 8, withPad: " ", startingAt: 0), color: color))"
    }

    private func levelInfo(_ level: Logger.Level) -> (emoji: String, color: ANSIColor, text: String) {
        switch level {
        case .trace:
            return ("💬", .gray, "trace")
        case .debug:
            return ("🔍", .cyan, "debug")
        case .info:
            return ("💡", .green, "info")
        case .notice:
            return ("📋", .blue, "notice")
        case .warning:
            return ("🚨", .yellow, "warning")
        case .error:
            return ("❌", .red, "error")
        case .critical:
            return ("🔥", .magenta, "critical")
        }
    }

    private func formatMetadata(_ metadata: Logger.Metadata?) -> String {
        let combined = self.metadata.merging(metadata ?? [:]) { $1 }
        guard !combined.isEmpty else { return "" }

        let items = combined.map { key, value in
            let valueString = String(describing: value)
            return "[\(colorize(valueString, color: .blue))]"
        }.joined(separator: " ")

        return items
    }

    // MARK: - ANSI Colors

    private enum ANSIColor: String {
        case black = "\u{001B}[30m"
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case magenta = "\u{001B}[35m"
        case cyan = "\u{001B}[36m"
        case white = "\u{001B}[37m"
        case gray = "\u{001B}[90m"
        case reset = "\u{001B}[0m"
    }

    private func colorize(_ text: String, color: ANSIColor) -> String {
        guard Self.supportsANSI else { return text }
        return "\(color.rawValue)\(text)\(ANSIColor.reset.rawValue)"
    }
}

// MARK: - Factory

extension ColoredLogHandler {
    /// 创建彩色日志处理器工厂
    static func makeFactory() -> @Sendable (String) -> LogHandler {
        return { label in
            ColoredLogHandler(label: label)
        }
    }
}
