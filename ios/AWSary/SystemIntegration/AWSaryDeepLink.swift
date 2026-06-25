import Foundation

enum AWSaryDeepLink: Hashable, Sendable {
    case service(id: Int)
    case hero(id: String)
    case userGroup(id: String)

    init?(url: URL) {
        guard url.scheme?.localizedCaseInsensitiveCompare("awsary") == .orderedSame else {
            return nil
        }

        let host = url.host?.lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch (host, pathComponents.first) {
        case ("service", let rawID?):
            guard let id = Int(rawID) else { return nil }
            self = .service(id: id)
        case ("hero", let id?):
            self = .hero(id: id)
        case ("user-group", let id?):
            self = .userGroup(id: id)
        default:
            return nil
        }
    }

    var url: URL {
        switch self {
        case .service(let id):
            URL(string: "awsary://service/\(id)")!
        case .hero(let id):
            URL(string: "awsary://hero/\(id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id)")!
        case .userGroup(let id):
            URL(string: "awsary://user-group/\(id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id)")!
        }
    }
}

@MainActor
final class AWSaryDeepLinkDispatcher: ObservableObject {
    static let shared = AWSaryDeepLinkDispatcher()

    @Published var pendingDeepLink: AWSaryDeepLink?

    private init() {}

    func open(_ deepLink: AWSaryDeepLink) {
        pendingDeepLink = deepLink
    }

    func open(_ url: URL) {
        guard let deepLink = AWSaryDeepLink(url: url) else { return }
        open(deepLink)
    }
}
