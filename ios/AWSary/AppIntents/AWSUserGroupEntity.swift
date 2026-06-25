import AppIntents
import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

struct AWSUserGroupEntity: IndexedEntity, URLRepresentableEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "AWS User Group",
        synonyms: ["AWS community group", "AWS meetup"]
    )
    static var defaultQuery = AWSUserGroupEntityQuery()
    static var urlRepresentation: URLRepresentation {
        "awsary://user-group/\(.id)"
    }

    let id: String
    let name: String
    let summary: String
    let city: String
    let region: String
    let country: String
    let locationName: String
    let imageURL: String
    let joinURL: String
    let platformName: String
    let topics: [String]
    let links: [CommunityUserGroupLink]
    let networkName: String

    init(userGroup: CommunityUserGroup) {
        id = userGroup.id
        name = userGroup.name
        summary = userGroup.summary
        city = userGroup.location.city ?? ""
        region = userGroup.location.region ?? ""
        country = userGroup.location.country
        locationName = userGroup.location.displayName
        imageURL = userGroup.imageURL
        joinURL = userGroup.joinURL
        platformName = userGroup.platformName
        topics = userGroup.topics
        links = userGroup.links
        networkName = userGroup.networkName ?? ""
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(locationName)",
            image: imageURL.awsaryDisplayImage()
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = name
        attributes.displayName = name
        attributes.contentDescription = summary.awsaryPlainTextSummary
        attributes.keywords = searchableFields
        attributes.contentURL = deepLink.url
        attributes.url = deepLink.url
        if let url = URL(string: imageURL), !imageURL.isEmpty {
            attributes.thumbnailURL = url
        }
        return attributes
    }

    var deepLink: AWSaryDeepLink {
        .userGroup(id: id)
    }

    fileprivate var searchableFields: [String] {
        [
            name,
            summary,
            city,
            region,
            country,
            locationName,
            imageURL,
            joinURL,
            platformName,
            networkName
        ] + topics + links.flatMap { [$0.label, $0.url] }
    }
}

struct AWSUserGroupEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    func entities(for identifiers: [AWSUserGroupEntity.ID]) async throws -> [AWSUserGroupEntity] {
        var entities: [AWSUserGroupEntity] = []
        for identifier in identifiers {
            if let group = await AWSaryContentDataSource.shared.userGroup(id: identifier) {
                entities.append(AWSUserGroupEntity(userGroup: group))
            }
        }
        return entities
    }

    func suggestedEntities() async throws -> [AWSUserGroupEntity] {
        Array(try await allEntities().prefix(20))
    }

    func allEntities() async throws -> [AWSUserGroupEntity] {
        await AWSaryContentDataSource.shared.userGroups().map(AWSUserGroupEntity.init(userGroup:))
    }

    func entities(matching string: String) async throws -> [AWSUserGroupEntity] {
        await AWSaryContentDataSource.shared.userGroups(matching: string).map(AWSUserGroupEntity.init(userGroup:))
    }
}
