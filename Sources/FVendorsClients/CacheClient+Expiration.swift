import Foundation

extension CacheClient {
    /// 为缓存添加“过期”封装层。
    ///
    /// - Parameters:
    ///   - defaultTTL: 默认过期时间；为 `nil` 时表示默认不过期（写入保持原始 Data，不增加封装）。
    ///   - clock: 时间来源（用于测试注入）。
    /// - Returns: 带过期处理逻辑的新 CacheClient。
    public func expiring(
        defaultTTL: Duration? = nil,
        clock: @escaping @Sendable () -> Date = Date.init
    ) -> CacheClient {
        let base = self

        return CacheClient(
            readData: { key in
                guard let raw = try await base.readData(key) else { return nil }

                if let envelope = CacheEnvelope.decode(from: raw) {
                    if let expiresAt = envelope.expiresAt, expiresAt <= clock() {
                        try await base.remove(key)
                        return nil
                    }
                    return envelope.payload
                }

                return raw
            },
            writeData: { data, key in
                guard let defaultTTL else {
                    try await base.writeData(data, key)
                    return
                }

                let expiresAt = clock().addingTimeInterval(CacheEnvelope.timeInterval(from: defaultTTL))
                let wrapped = try CacheEnvelope.encode(payload: data, expiresAt: expiresAt)
                try await base.writeData(wrapped, key)
            },
            remove: { key in
                try await base.remove(key)
            },
            removeAll: {
                try await base.removeAll()
            }
        )
    }

    /// 写入带过期时间的 Data（需要配合 `expiring(...)` 读取/解包）。
    public func writeData(
        _ data: Data,
        forKey key: String,
        expiresIn ttl: Duration,
        clock: @escaping @Sendable () -> Date = Date.init
    ) async throws {
        let expiresAt = clock().addingTimeInterval(CacheEnvelope.timeInterval(from: ttl))
        try await writeData(data, forKey: key, expiresAt: expiresAt)
    }

    /// 写入在指定时间过期的 Data（需要配合 `expiring(...)` 读取/解包）。
    public func writeData(
        _ data: Data,
        forKey key: String,
        expiresAt: Date
    ) async throws {
        let wrapped = try CacheEnvelope.encode(payload: data, expiresAt: expiresAt)
        try await writeData(wrapped, key)
    }

    /// 写入带过期时间的 Codable（需要配合 `expiring(...)` 读取/解包）。
    public func write<T: Encodable>(
        _ value: T,
        forKey key: String,
        expiresIn ttl: Duration,
        encoder: JSONEncoder = JSONEncoder(),
        clock: @escaping @Sendable () -> Date = Date.init
    ) async throws {
        let data = try encoder.encode(value)
        try await writeData(data, forKey: key, expiresIn: ttl, clock: clock)
    }
}

// MARK: - Envelope

/// 过期封装格式。
///
/// 说明：
/// - **仅**用于 FVendors 内部模块之间共享（`FVendorsClients` <-> `FVendorsClientsLive`）
/// - 对外使用请通过 `CacheClient.expiring(...)` / `CacheClient.write...expires...` API
package struct CacheEnvelope: Codable, Sendable {
    /// magic 前缀，用于区分“原始 Data”与“过期封装”
    package static let magic = Data([0x46, 0x56, 0x43, 0x61, 0x63, 0x68, 0x65, 0x31]) // "FVCache1"

    /// 过期时间；为 `nil` 表示永不过期
    package let expiresAt: Date?

    /// 原始 payload
    package let payload: Data

    package static func encode(payload: Data, expiresAt: Date?) throws -> Data {
        let envelope = CacheEnvelope(expiresAt: expiresAt, payload: payload)
        let encoded = try JSONEncoder().encode(envelope)
        return magic + encoded
    }

    package static func decode(from data: Data) -> CacheEnvelope? {
        guard data.count > magic.count else { return nil }
        guard data.prefix(magic.count) == magic else { return nil }

        let json = data.dropFirst(magic.count)
        return try? JSONDecoder().decode(CacheEnvelope.self, from: Data(json))
    }

    package static func hasMagicPrefix(_ data: Data) -> Bool {
        data.count > magic.count && data.prefix(magic.count) == magic
    }

    package static func timeInterval(from duration: Duration) -> TimeInterval {
        let components = duration.components
        let seconds = TimeInterval(components.seconds)
        let attoseconds = TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
        return seconds + attoseconds
    }
}
