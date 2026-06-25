import Foundation

actor AWSaryContentDataSource {
    static let shared = AWSaryContentDataSource()

    private let indexSchemaVersion = "app-intents-index-v4"

    private var cachedServices: [awsService]?
    private var cachedHeroes: [CommunityMember]?
    private var cachedUserGroups: [CommunityUserGroup]?

    private init() {}

    func services() async -> [awsService] {
        if let cachedServices { return cachedServices }
        let loaded = loadResource("aws_services", as: [awsService].self)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        cachedServices = loaded
        return loaded
    }

    func service(id: Int) async -> awsService? {
        await services().first { $0.id == id }
    }

    func services(matching query: String) async -> [awsService] {
        let allServices = await services()
        return AWSaryAppEntitySearch.sortedMatches(
            query: query,
            in: allServices,
            title: { $0.longName },
            fields: { service in
                [
                    service.name,
                    service.longName,
                    service.shortDesctiption,
                    service.imageURL.replacingOccurrences(of: "https://static.tig.pt/awsary/logos/Arch_", with: "")
                ]
            }
        )
    }

    func heroes() async -> [CommunityMember] {
        if let cachedHeroes { return cachedHeroes }
        let loaded = loadResource("community_members", as: [CommunityMember].self)
            .filter { member in
                member.statuses.contains { $0.localizedCaseInsensitiveContains("AWS Hero") }
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        cachedHeroes = loaded
        return loaded
    }

    func hero(id: String) async -> CommunityMember? {
        await heroes().first { $0.id == id }
    }

    func heroes(matching query: String) async -> [CommunityMember] {
        let allHeroes = await heroes()
        return AWSaryAppEntitySearch.sortedMatches(
            query: query,
            in: allHeroes,
            title: { $0.name },
            fields: { [$0.name, $0.location, $0.bio] + $0.statuses + $0.specialties }
        )
    }

    func userGroups() async -> [CommunityUserGroup] {
        if let cachedUserGroups { return cachedUserGroups }
        let loaded = loadResource("community_user_groups", as: [CommunityUserGroup].self)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        cachedUserGroups = loaded
        return loaded
    }

    func userGroup(id: String) async -> CommunityUserGroup? {
        await userGroups().first { $0.id == id }
    }

    func userGroups(matching query: String) async -> [CommunityUserGroup] {
        let allGroups = await userGroups()
        return AWSaryAppEntitySearch.sortedMatches(
            query: query,
            in: allGroups,
            title: { $0.name },
            fields: {
                [
                    $0.name,
                    $0.summary,
                    $0.location.displayName,
                    $0.location.city ?? "",
                    $0.location.region ?? "",
                    $0.location.country,
                    $0.platformName,
                    $0.networkName ?? ""
                ] + $0.topics
            }
        )
    }

    func contentVersion() async -> String {
        let resourceNames = ["aws_services", "community_members", "community_user_groups"]
        let components = resourceNames.map { name -> String in
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else {
                return "\(name):missing"
            }

            let size = values.fileSize ?? 0
            let modified = values.contentModificationDate?.timeIntervalSince1970 ?? 0
            return "\(name):\(size):\(Int(modified))"
        }

        let serviceCount = await services().count
        let heroCount = await heroes().count
        let userGroupCount = await userGroups().count
        let counts = "\(serviceCount):\(heroCount):\(userGroupCount)"
        return ([indexSchemaVersion] + components + [counts]).joined(separator: "|")
    }

    private func loadResource<T: Decodable>(_ name: String, as type: T.Type) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return emptyValue(for: type)
        }

        return decoded
    }

    private func emptyValue<T: Decodable>(for type: T.Type) -> T {
        if let emptyArray = [] as? T {
            return emptyArray
        }
        fatalError("Unsupported resource type \(type)")
    }
}
