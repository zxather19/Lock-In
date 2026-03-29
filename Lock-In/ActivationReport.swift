import Foundation

struct ActivationReport: Equatable {
    enum Level: Equatable {
        case success
        case warning
        case failure
    }

    let level: Level
    let title: String
    let details: [String]

    var summary: String {
        details.joined(separator: "\n")
    }
}
