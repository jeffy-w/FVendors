import FVendorsClients
import FVendorsClientsLive
import Foundation
import Testing

@Suite("CacheClient Tests")
struct CacheClientTests {
    @Test("Read returns nil for missing key")
    func readReturnsNilForMissingKey() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = CacheClient.fileSystem(directory: tempDir)

        let data = try await cache.readData("missing")
        #expect(data == nil)
    }

    @Test("Write then read Data returns same bytes")
    func writeThenReadData() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = CacheClient.fileSystem(directory: tempDir)

        let expected = Data([0x01, 0x02, 0x03])
        try await cache.writeData(expected, "k1")

        let actual = try await cache.readData("k1")
        #expect(actual == expected)
    }

    @Test("Write then read Codable returns same value")
    func writeThenReadCodable() async throws {
        struct Value: Codable, Equatable {
            let name: String
            let count: Int
        }

        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = CacheClient.fileSystem(directory: tempDir)

        let expected = Value(name: "hello", count: 42)
        try await cache.write(expected, forKey: "v")

        let actual = try await cache.read(Value.self, forKey: "v")
        #expect(actual == expected)
    }

    @Test("Remove deletes key")
    func removeDeletesKey() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = CacheClient.fileSystem(directory: tempDir)

        try await cache.writeData(Data("x".utf8), "toRemove")
        #expect(try await cache.readData("toRemove") != nil)

        try await cache.remove("toRemove")
        #expect(try await cache.readData("toRemove") == nil)
    }

    @Test("Overwrite updates stored value")
    func overwriteUpdatesStoredValue() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = CacheClient.fileSystem(directory: tempDir)

        try await cache.writeData(Data("a".utf8), "k")
        try await cache.writeData(Data("b".utf8), "k")

        let actual = try await cache.readData("k")
        #expect(actual == Data("b".utf8))
    }

    @Test("Expiring wrapper with defaultTTL nil does not alter storage")
    func expiringWrapperDefaultNoExpirationDoesNotAlterStorage() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let base = CacheClient.fileSystem(directory: tempDir)
        let wrapped = base.expiring()

        let expected = Data("raw".utf8)
        try await wrapped.writeData(expected, "k")

        let stored = try await base.readData("k")
        #expect(stored == expected)
    }

    @Test("Expiring wrapper returns nil after expiration and removes entry")
    func expiringWrapperExpiresAndRemoves() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let base = CacheClient.fileSystem(directory: tempDir)

        final class ClockBox: @unchecked Sendable {
            private let lock = NSLock()
            private var now: Date

            init(now: Date) {
                self.now = now
            }

            func get() -> Date {
                lock.lock()
                defer { lock.unlock() }
                return now
            }

            func set(_ date: Date) {
                lock.lock()
                now = date
                lock.unlock()
            }
        }

        let clockBox = ClockBox(now: Date(timeIntervalSince1970: 0))
        let wrapped = base.expiring(defaultTTL: .seconds(10), clock: { clockBox.get() })

        try await wrapped.writeData(Data("value".utf8), "k")
        #expect(try await wrapped.readData("k") == Data("value".utf8))

        clockBox.set(Date(timeIntervalSince1970: 11))
        #expect(try await wrapped.readData("k") == nil)
        #expect(try await base.readData("k") == nil)
    }
}
