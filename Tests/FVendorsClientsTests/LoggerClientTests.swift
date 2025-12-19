import FVendorsClients
import FVendorsModels
import Testing

@Suite("LoggerClient Tests")
@MainActor
struct LoggerClientTests {
    @Test("Collecting logger captures debug messages")
    func collectingLoggerCapturesDebugMessages() async {
        let storage = LogStorage()
        let logger = LoggerClient.collecting(storage: storage)

        logger.debug("Debug message")

        // 等待异步任务完成
        try? await Task.sleep(for: .milliseconds(10))

        #expect(storage.logs.count == 1)
        #expect(storage.logs[0].0 == "Debug message")
        #expect(storage.logs[0].1 == .debug)
    }

    @Test("Collecting logger captures info messages")
    func collectingLoggerCapturesInfoMessages() async {
        let storage = LogStorage()
        let logger = LoggerClient.collecting(storage: storage)

        logger.info("Info message")

        try? await Task.sleep(for: .milliseconds(10))

        #expect(storage.logs.count == 1)
        #expect(storage.logs[0].0 == "Info message")
        #expect(storage.logs[0].1 == .info)
    }

    @Test("Collecting logger captures warning messages")
    func collectingLoggerCapturesWarningMessages() async {
        let storage = LogStorage()
        let logger = LoggerClient.collecting(storage: storage)

        logger.warning("Warning message")

        try? await Task.sleep(for: .milliseconds(10))

        #expect(storage.logs.count == 1)
        #expect(storage.logs[0].0 == "Warning message")
        #expect(storage.logs[0].1 == .warning)
    }

    @Test("Collecting logger captures error messages")
    func collectingLoggerCapturesErrorMessages() async {
        let storage = LogStorage()
        let logger = LoggerClient.collecting(storage: storage)

        logger.error("Error message")

        try? await Task.sleep(for: .milliseconds(10))

        #expect(storage.logs.count == 1)
        #expect(storage.logs[0].0 == "Error message")
        #expect(storage.logs[0].1 == .error)
    }

    @Test("Collecting logger captures critical messages")
    func collectingLoggerCapturesCriticalMessages() async {
        let storage = LogStorage()
        let logger = LoggerClient.collecting(storage: storage)

        logger.critical("Critical message")

        try? await Task.sleep(for: .milliseconds(10))

        #expect(storage.logs.count == 1)
        #expect(storage.logs[0].0 == "Critical message")
        #expect(storage.logs[0].1 == .critical)
    }

    @Test("Collecting logger captures multiple messages")
    func collectingLoggerCapturesMultipleMessages() async {
        let storage = LogStorage()
        let logger = LoggerClient.collecting(storage: storage)

        logger.info("First message")
        logger.error("Second message")
        logger.debug("Third message")

        try? await Task.sleep(for: .milliseconds(10))

        #expect(storage.logs.count == 3)
        #expect(storage.logs[0].0 == "First message")
        #expect(storage.logs[0].1 == .info)
        #expect(storage.logs[1].0 == "Second message")
        #expect(storage.logs[1].1 == .error)
        #expect(storage.logs[2].0 == "Third message")
        #expect(storage.logs[2].1 == .debug)
    }

    @Test("Noop logger does not crash")
    func noopLoggerDoesNotCrash() {
        let logger = LoggerClient.noop

        // 这些调用不应该崩溃
        logger.debug("Debug")
        logger.info("Info")
        logger.warning("Warning")
        logger.error("Error")
        logger.critical("Critical")

        // 测试通过说明没有崩溃
        #expect(Bool(true))
    }
}
