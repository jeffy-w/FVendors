import Foundation
import FVendorsModels

extension NetworkClient {
    /// Returns a client that retries recoverable failures from the wrapped client.
    ///
    /// The default retry policy retries only recoverable `AppError` values such as
    /// `.networkError(.noConnection)` and `.networkError(.timeout)`.
    public func retrying(
        maxAttempts: Int = 3,
        delay: Duration = .zero,
        shouldRetry: @escaping @Sendable (Error) -> Bool = { error in
            guard let appError = error as? AppError else { return false }
            return appError.isRecoverable
        }
    ) -> NetworkClient {
        let base = self
        let attempts = max(1, maxAttempts)

        return NetworkClient { request in
            var currentAttempt = 1
            while true {
                do {
                    return try await base.request(request)
                } catch {
                    guard currentAttempt < attempts, shouldRetry(error) else {
                        throw error
                    }

                    currentAttempt += 1
                    if delay > .zero {
                        try await Task.sleep(for: delay)
                    }
                }
            }
        }
    }
}
