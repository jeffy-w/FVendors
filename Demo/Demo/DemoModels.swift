import Foundation

struct DemoUser: Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let email: String
}

enum DemoDataSource: String, Equatable, Sendable {
    case network
    case cache

    var displayName: String {
        rawValue.capitalized
    }
}
