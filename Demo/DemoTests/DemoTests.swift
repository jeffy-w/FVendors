import Foundation
import Testing
import FVendors
@testable import Demo

@MainActor
struct DemoTests {
    actor RequestCounter {
        private var value = 0

        func increment() {
            value += 1
        }

        func count() -> Int {
            value
        }
    }

    @Test("Load user falls back to cache after first network request")
    func loadUserUsesNetworkThenCache() async throws {
        let expected = DemoUser(id: 1, name: "Taylor Swift", email: "taylor@example.com")
        let counter = RequestCounter()
        let cache = CacheClient.inMemory()
        let network = NetworkClient.mock { _ in
            await counter.increment()
            return try JSONEncoder().encode(expected)
        }

        let viewModel = DemoViewModel(
            dependencies: .test(
                network: network,
                cache: cache
            )
        )

        await viewModel.loadUser()
        #expect(viewModel.user == expected)
        #expect(viewModel.dataSource == .network)
        #expect(viewModel.statusMessage == "Loaded from network")
        #expect(await counter.count() == 1)

        await viewModel.loadUser()
        #expect(viewModel.user == expected)
        #expect(viewModel.dataSource == .cache)
        #expect(viewModel.statusMessage == "Loaded from cache")
        #expect(await counter.count() == 1)
    }

    @Test("Clearing cache resets state and forces another request")
    func clearCacheResetsState() async throws {
        let expected = DemoUser(id: 1, name: "Taylor Swift", email: "taylor@example.com")
        let counter = RequestCounter()
        let cache = CacheClient.inMemory()
        let network = NetworkClient.mock { _ in
            await counter.increment()
            return try JSONEncoder().encode(expected)
        }

        let viewModel = DemoViewModel(
            logger: .noop,
            network: network,
            cache: cache
        )

        await viewModel.loadUser()
        #expect(await counter.count() == 1)

        await viewModel.clearCache()
        #expect(viewModel.user == nil)
        #expect(viewModel.dataSource == nil)
        #expect(viewModel.statusMessage == "Cache cleared")

        await viewModel.loadUser()
        #expect(viewModel.user == expected)
        #expect(viewModel.dataSource == .network)
        #expect(await counter.count() == 2)
    }

    @Test("Dependency container wires logger network and cache")
    func dependencyContainerWiresClients() async throws {
        let expected = DemoUser(id: 2, name: "Alex", email: "alex@example.com")
        let storage = LogStorage()
        let dependencies = AppDependencies.test(
            logger: .collecting(storage: storage),
            network: .mock(returning: try JSONEncoder().encode(expected)),
            cache: .inMemory()
        )
        let viewModel = DemoViewModel(dependencies: dependencies)

        await viewModel.loadUser()
        try? await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.user == expected)
        #expect(viewModel.dataSource == .network)
        #expect(storage.records.contains { $0.metadata["source"] == "network" })
    }

    @Test("Load user reports error state when network fails")
    func loadUserReportsErrorState() async throws {
        let cache = CacheClient.inMemory()
        let network = NetworkClient.failing(with: AppError.networkError(.noConnection))
        let viewModel = DemoViewModel(
            logger: .noop,
            network: network,
            cache: cache
        )

        await viewModel.loadUser()

        #expect(viewModel.user == nil)
        #expect(viewModel.dataSource == nil)
        #expect(viewModel.lastErrorMessage != nil)
        #expect(viewModel.statusMessage.hasPrefix("Failed:"))
    }
}
