import CoreSpotlight
import Foundation

enum AWSaryContentIndexer {
    private static let indexedContentVersionKey = "awsary.indexedContentVersion"

    static func scheduleIndexingIfNeeded() {
        Task.detached(priority: .utility) {
            await indexIfNeeded()
        }
    }

    static func indexIfNeeded(force: Bool = false) async {
        let version = await AWSaryContentDataSource.shared.contentVersion()

        if !force, UserDefaults.standard.string(forKey: indexedContentVersionKey) == version {
            return
        }

        do {
            let dataSource = AWSaryContentDataSource.shared
            let services = await dataSource.services().map(AWSServiceEntity.init(service:))
            let heroes = await dataSource.heroes().map(AWSHeroEntity.init(member:))
            let userGroups = await dataSource.userGroups().map(AWSUserGroupEntity.init(userGroup:))

            try await CSSearchableIndex.default().indexAppEntities(services, priority: 10)
            try await CSSearchableIndex.default().indexAppEntities(heroes, priority: 6)
            try await CSSearchableIndex.default().indexAppEntities(userGroups, priority: 6)

            UserDefaults.standard.set(version, forKey: indexedContentVersionKey)
        } catch {
            print("AWSary App Intents indexing failed: \(error)")
        }
    }
}
