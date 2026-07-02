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

struct TomatoEmoji: Identifiable, Equatable, Sendable {
    let id: UUID
    let bodyColor: String
    let eyeType: EyeType
    let mouthType: MouthType
    let blushVisible: Bool
    
    enum EyeType: String, CaseIterable, Sendable {
        case normal = "●"
        case happy = "^"
        case blink = ">"
        case circles = "O"
    }
    
    enum MouthType: String, CaseIterable, Sendable {
        case smile = "◡"
        case open = "O"
        case straight = "_"
        case small = "v"
    }
    
    static func random() -> TomatoEmoji {
        TomatoEmoji(
            id: UUID(),
            bodyColor: ["#FF6347", "#FF4500", "#DC143C", "#FF0000"].randomElement() ?? "#FF6347",
            eyeType: EyeType.allCases.randomElement() ?? .normal,
            mouthType: MouthType.allCases.randomElement() ?? .smile,
            blushVisible: Bool.random()
        )
    }
}
