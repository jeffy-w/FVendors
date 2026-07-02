import Foundation
import FVendors
import Observation

@MainActor
@Observable
final class DemoViewModel {
    private enum Constants {
        static let cacheKey = "demo.user"
        static let endpoint = URL(string: "https://demo.local/user")!
    }

    private let logger: LoggerClient
    private let network: NetworkClient
    private let cache: CacheClient

    var user: DemoUser?
    var dataSource: DemoDataSource?
    var statusMessage = "Idle"
    var lastErrorMessage: String?
    var isLoading = false
    
    // Tomato Emojis State
    var tomatoes: [TomatoEmoji] = []

    init(
        logger: LoggerClient = .live,
        network: NetworkClient = DemoViewModel.makeDemoNetworkClient(),
        cache: CacheClient = .live
    ) {
        self.logger = logger
        self.network = network
        self.cache = cache
    }

    func spawnTomato() {
        let newTomato = TomatoEmoji.random()
        tomatoes.append(newTomato)
        logger.info("Spawned composite tomato: \(newTomato.eyeType)/\(newTomato.mouthType)")
    }

    func clearTomatoes() {
        tomatoes.removeAll()
        logger.info("Cleared all tomatoes")
    }

    func loadUser() async {
        guard !isLoading else { return }

        isLoading = true
        lastErrorMessage = nil
        statusMessage = "Loading..."
        logger.info("Demo load started")

        defer { isLoading = false }

        do {
            if let cached = try await cache.read(DemoUser.self, forKey: Constants.cacheKey) {
                user = cached
                dataSource = .cache
                statusMessage = "Loaded from cache"
                logger.info("Demo user loaded from cache")
                return
            }

            let request = APIRequestBuilder.buildRequest(
                url: Constants.endpoint,
                method: .get
            )
            let fetched = try await network.request(request, as: DemoUser.self)
            try await cache.write(fetched, forKey: Constants.cacheKey)

            user = fetched
            dataSource = .network
            statusMessage = "Loaded from network"
            logger.info("Demo user loaded from network")
        } catch {
            let appError = AppError.from(error)
            user = nil
            dataSource = nil
            lastErrorMessage = appError.userMessage
            statusMessage = "Failed: \(appError.userMessage)"
            logger.error("Demo load failed: \(appError.userMessage)")
        }
    }

    func clearCache() async {
        do {
            try await cache.removeAll()
            user = nil
            dataSource = nil
            lastErrorMessage = nil
            statusMessage = "Cache cleared"
            logger.info("Demo cache cleared")
        } catch {
            let appError = AppError.from(error)
            lastErrorMessage = appError.userMessage
            statusMessage = "Failed: \(appError.userMessage)"
            logger.error("Demo cache clear failed: \(appError.userMessage)")
        }
    }

    nonisolated static func makeDemoNetworkClient(
        delay: Duration = .milliseconds(400)
    ) -> NetworkClient {
        NetworkClient.mock { _ in
            try await Task.sleep(for: delay)
            let user = DemoUser(
                id: 1,
                name: "Taylor Swift",
                email: "taylor@example.com"
            )
            return try JSONEncoder().encode(user)
        }
    }
}
