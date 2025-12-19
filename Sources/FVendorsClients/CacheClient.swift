import Foundation
import FVendorsModels

/// 本地缓存客户端（key-value，支持存取 Codable）。
///
/// 设计目标：
/// - 纯 Swift 接口（便于注入、替换与测试）
/// - 默认以 Data 为底层读写单位，提供 Codable 便捷方法
/// - 支持可选的 TTL 过期机制（通过 `.expiring(...)` 包装）
/// - 线程安全（底层实现负责并发控制）
///
/// 使用示例：
/// ```swift
/// let cache = CacheClient.live
/// try await cache.write(user, forKey: "currentUser")
/// let cached = try await cache.read(User.self, forKey: "currentUser")
/// ```
///
/// - SeeAlso: [Cache 使用文档](../../Docs/Cache.md)
public struct CacheClient: Sendable {
    /// 读取原始数据
    public var readData: @Sendable (_ key: String) async throws -> Data?

    /// 写入原始数据
    public var writeData: @Sendable (_ data: Data, _ key: String) async throws -> Void

    /// 删除指定 key
    public var remove: @Sendable (_ key: String) async throws -> Void

    /// 清空缓存
    public var removeAll: @Sendable () async throws -> Void

    public init(
        readData: @escaping @Sendable (_ key: String) async throws -> Data?,
        writeData: @escaping @Sendable (_ data: Data, _ key: String) async throws -> Void,
        remove: @escaping @Sendable (_ key: String) async throws -> Void,
        removeAll: @escaping @Sendable () async throws -> Void
    ) {
        self.readData = readData
        self.writeData = writeData
        self.remove = remove
        self.removeAll = removeAll
    }
}

// MARK: - Codable 便捷方法

extension CacheClient {
    /// 读取并解码为指定类型
    public func read<T: Decodable>(
        _ type: T.Type,
        forKey key: String,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T? {
        guard let data = try await readData(key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.persistenceError(.fetchFailed)
        }
    }

    /// 编码并写入指定类型
    public func write<T: Encodable>(
        _ value: T,
        forKey key: String,
        encoder: JSONEncoder = JSONEncoder()
    ) async throws {
        do {
            let data = try encoder.encode(value)
            try await writeData(data, key)
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.persistenceError(.saveFailed)
        }
    }
}

// MARK: - 测试辅助

extension CacheClient {
    /// 空实现（用于不需要缓存的场景）
    public static let noop = CacheClient(
        readData: { _ in nil },
        writeData: { _, _ in },
        remove: { _ in },
        removeAll: { }
    )

    /// 内存缓存（用于测试）
    public static func inMemory() -> CacheClient {
        actor Store {
            var storage: [String: Data] = [:]

            func read(_ key: String) -> Data? {
                storage[key]
            }

            func write(_ data: Data, forKey key: String) {
                storage[key] = data
            }

            func remove(_ key: String) {
                storage.removeValue(forKey: key)
            }

            func removeAll() {
                storage.removeAll()
            }
        }

        let store = Store()

        return CacheClient(
            readData: { key in
                await store.read(key)
            },
            writeData: { data, key in
                await store.write(data, forKey: key)
            },
            remove: { key in
                await store.remove(key)
            },
            removeAll: {
                await store.removeAll()
            }
        )
    }
}
