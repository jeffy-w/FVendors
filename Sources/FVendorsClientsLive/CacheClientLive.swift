import CryptoKit
import FVendorsClients
import Foundation
import FVendorsModels

extension CacheClient {
    /// 生产环境的缓存实现（基于本地文件系统，默认使用 Caches 目录）
    public static let live: CacheClient = CacheClient.fileSystem()

    /// 基于文件系统的缓存实现
    /// - Parameter directory: 缓存目录（默认：`cachesDirectory/FVendorsCache`）
    public static func fileSystem(directory: URL? = nil) -> CacheClient {
        let store = FileCacheStore(baseURL: directory ?? FileCacheStore.defaultBaseURL)

        return CacheClient(
            readData: { key in
                try await store.read(key: key)
            },
            writeData: { data, key in
                try await store.write(data: data, key: key)
            },
            remove: { key in
                try await store.remove(key: key)
            },
            removeAll: {
                try await store.removeAll()
            }
        )
    }
}

// MARK: - File-backed store

actor FileCacheStore {
    static let defaultBaseURL: URL = {
        // Cache 语义：系统可在空间不足时清理；适合临时/可重建数据
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (caches ?? FileManager.default.temporaryDirectory)
            .appending(path: "FVendorsCache", directoryHint: .isDirectory)
    }()

    private let baseURL: URL
    private var lastPurgeScheduledAt: Date?
    private var pendingPurgeTask: Task<Void, Never>?

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    deinit {
        pendingPurgeTask?.cancel()
    }

    func read(key: String) throws -> Data? {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            if CacheEnvelope.hasMagicPrefix(data) {
                scheduleBackgroundPurgeIfNeeded()
            }
            return data
        } catch {
            throw AppError.persistenceError(.fetchFailed)
        }
    }

    func write(data: Data, key: String) throws {
        do {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        } catch {
            throw AppError.persistenceError(.saveFailed)
        }

        let url = fileURL(for: key)
        do {
            try data.write(to: url, options: [.atomic])
            if CacheEnvelope.hasMagicPrefix(data) {
                scheduleBackgroundPurgeIfNeeded()
            }
        } catch {
            throw AppError.persistenceError(.saveFailed)
        }
    }

    func remove(key: String) throws {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw AppError.persistenceError(.deleteFailed)
        }
    }

    func removeAll() throws {
        guard FileManager.default.fileExists(atPath: baseURL.path) else {
            return
        }

        do {
            let urls = try FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
            for url in urls {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            throw AppError.persistenceError(.deleteFailed)
        }
    }

    /// 节流地调度一次后台过期清理。
    ///
    /// 触发时机：读/写到“带过期封装（magic 前缀）”的数据。
    private func scheduleBackgroundPurgeIfNeeded(
        now: @escaping @Sendable () -> Date = Date.init,
        minInterval: TimeInterval = 30,
        delay: Duration = .seconds(2),
        limit: Int = 200
    ) {
        let current = now()
        if let last = lastPurgeScheduledAt, current.timeIntervalSince(last) < minInterval {
            return
        }

        lastPurgeScheduledAt = current

        pendingPurgeTask?.cancel()
        let baseURL = self.baseURL
        pendingPurgeTask = Task.detached(priority: .background) {
            try? await Task.sleep(for: delay)
            _ = try? FileCacheStore.purgeExpiredFiles(baseURL: baseURL, now: now(), limit: limit)
        }
    }

    /// 扫描目录并删除已过期的封装文件。
    ///
    /// - Note: 这是一个“尽力而为”的清理：
    ///   - 会忽略单个文件的读取/删除失败
    ///   - 仅处理带 magic 前缀且能成功解码的封装文件
    ///   - 用 `limit` 限制单次 IO 开销
    nonisolated static func purgeExpiredFiles(
        baseURL: URL,
        now: Date = Date(),
        limit: Int = 200
    ) throws -> Int {
        guard FileManager.default.fileExists(atPath: baseURL.path) else {
            return 0
        }

        let urls = try FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
        var removed = 0

        for url in urls {
            if removed >= limit { break }
            guard url.pathExtension == "cache" else { continue }

            guard let data = try? Data(contentsOf: url) else { continue }
            guard let envelope = CacheEnvelope.decode(from: data) else { continue }
            guard let expiresAt = envelope.expiresAt, expiresAt <= now else { continue }

            do {
                try FileManager.default.removeItem(at: url)
                removed += 1
            } catch {
                // 忽略单个删除失败，继续批量处理
            }
        }

        return removed
    }

    private func fileURL(for key: String) -> URL {
        let hashed = Self.sha256Hex(key)
        return baseURL
            .appending(path: hashed)
            .appendingPathExtension("cache")
    }

    private static func sha256Hex(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
