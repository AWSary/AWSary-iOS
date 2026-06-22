import Foundation

struct CommunityUserGroup: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let summary: String
    let location: CommunityUserGroupLocation
    let imageURL: String
    let joinURL: String
    let platform: String
    let topics: [String]
    let links: [CommunityUserGroupLink]
    let foundedAt: String?
    let networkName: String?
    let metadataStatus: String
    let activity: CommunityUserGroupActivity?

    var platformName: String {
        switch platform {
        case "aws_community": "AWS Community"
        case "connpass": "Connpass"
        case "doorkeeper": "Doorkeeper"
        case "facebook": "Facebook"
        case "linkedin": "LinkedIn"
        case "luma": "Luma"
        case "meetup": "Meetup"
        case "website": "Website"
        default: platform.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    func matches(searchText: String, selectedCountry: String?, selectedPlatform: String?) -> Bool {
        if let selectedCountry, location.country != selectedCountry {
            return false
        }

        if let selectedPlatform, platformName != selectedPlatform {
            return false
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return true
        }

        return ([name, summary, location.displayName, location.country] + topics)
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(query)
    }
}

struct CommunityUserGroupLocation: Codable, Hashable {
    let displayName: String
    let city: String?
    let region: String?
    let country: String
    let countryCode: String
    let latitude: Double?
    let longitude: Double?
    let timezone: String?
}

struct CommunityUserGroupLink: Codable, Hashable, Identifiable {
    let label: String
    let url: String

    var id: String { url }
}

struct CommunityUserGroupActivity: Codable, Hashable {
    let capturedAt: String?
    let memberCount: Int?
    let leaderCount: Int?
    let ratingAverage: Double?
    let ratingCount: Int?
    let upcomingEventCount: Int?
    let pastEventCount: Int?
}

@MainActor
final class CommunityUserGroupStore: ObservableObject {
    @Published private(set) var groups: [CommunityUserGroup] = []
    @Published private(set) var errorMessage: String?

    init() {
        load()
    }

    func load() {
        errorMessage = nil

        guard let url = Bundle.main.url(forResource: "community_user_groups", withExtension: "json") else {
            errorMessage = "User Group data is not available."
            groups = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedGroups = try JSONDecoder().decode([CommunityUserGroup].self, from: data)
            groups = decodedGroups.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } catch {
            errorMessage = "User Group data could not be loaded."
            groups = []
        }
    }
}
