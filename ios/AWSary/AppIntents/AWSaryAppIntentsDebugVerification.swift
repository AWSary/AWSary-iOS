import Foundation

enum AWSaryAppIntentsDebugVerification {
    static func run() async -> [String] {
        var results: [String] = []

        let serviceQuery = AWSServiceEntityQuery()
        let heroQuery = AWSHeroEntityQuery()
        let userGroupQuery = AWSUserGroupEntityQuery()

        if let service = await AWSaryContentDataSource.shared.services().first {
            let resolved = (try? await serviceQuery.entities(for: [service.id])) ?? []
            let matches = (try? await serviceQuery.entities(matching: service.name)) ?? []
            results.append("Service lookup \(resolved.isEmpty ? "failed" : "passed"): \(service.id)")
            results.append("Service search \(matches.isEmpty ? "failed" : "passed"): \(service.name)")
            results.append("Service route: \(AWSaryDeepLink.service(id: service.id).url.absoluteString)")
        } else {
            results.append("Service data unavailable")
        }

        if let hero = await AWSaryContentDataSource.shared.heroes().first {
            let resolved = (try? await heroQuery.entities(for: [hero.id])) ?? []
            results.append("Hero lookup \(resolved.isEmpty ? "failed" : "passed"): \(hero.id)")
            results.append("Hero route: \(AWSaryDeepLink.hero(id: hero.id).url.absoluteString)")
        } else {
            results.append("Hero data unavailable")
        }

        if let userGroup = await AWSaryContentDataSource.shared.userGroups().first {
            let resolved = (try? await userGroupQuery.entities(for: [userGroup.id])) ?? []
            results.append("User Group lookup \(resolved.isEmpty ? "failed" : "passed"): \(userGroup.id)")
            results.append("User Group route: \(AWSaryDeepLink.userGroup(id: userGroup.id).url.absoluteString)")
        } else {
            results.append("User Group data unavailable")
        }

        return results
    }
}
