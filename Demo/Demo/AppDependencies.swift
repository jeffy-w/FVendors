import FVendors
import SwiftUI

struct AppDependencies: Sendable {
    let logger: LoggerClient
    let network: NetworkClient
    let cache: CacheClient

    var summary: String {
        "Logger + Network + Cache"
    }

    static let live = AppDependencies(
        logger: .live,
        network: NetworkClient.live.retrying(maxAttempts: 3, delay: .milliseconds(200)),
        cache: .live
    )

    static let demoOffline = AppDependencies(
        logger: .live,
        network: DemoViewModel.makeDemoNetworkClient(),
        cache: .live
    )

    static func test(
        logger: LoggerClient = .noop,
        network: NetworkClient = .noop,
        cache: CacheClient = .inMemory()
    ) -> AppDependencies {
        AppDependencies(logger: logger, network: network, cache: cache)
    }
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies = .demoOffline
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
