import AppIntents
import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

struct AWSHeroEntity: IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "AWS Hero",
        synonyms: ["AWS community hero", "AWS community member"]
    )
    static var defaultQuery = AWSHeroEntityQuery()

    let id: String
    let name: String
    let location: String
    let bio: String
    let statuses: [String]
    let specialties: [String]
    let imageURL: String
    let profileURL: String
    let links: [CommunityMemberLink]

    init(member: CommunityMember) {
        id = member.id
        name = member.name
        location = member.location
        bio = member.bio
        statuses = member.statuses
        specialties = member.specialties
        imageURL = member.imageURL
        profileURL = member.profileURL
        links = member.links
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(heroSubtitle)",
            image: imageURL.awsaryDisplayImage(displayStyle: .circular)
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = name
        attributes.displayName = name
        attributes.contentDescription = bio.awsaryPlainTextSummary
        attributes.keywords = searchableFields
        if let url = URL(string: imageURL), !imageURL.isEmpty {
            attributes.thumbnailURL = url
        }
        return attributes
    }

    var deepLink: AWSaryDeepLink {
        .hero(id: id)
    }

    private var heroSubtitle: String {
        ([location] + specialties).filter { !$0.isEmpty }.prefix(3).joined(separator: " - ")
    }

    fileprivate var searchableFields: [String] {
        [name, location, bio, imageURL, profileURL] + statuses + specialties + links.flatMap { [$0.label, $0.url] }
    }
}

struct AWSHeroEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    func entities(for identifiers: [AWSHeroEntity.ID]) async throws -> [AWSHeroEntity] {
        var entities: [AWSHeroEntity] = []
        for identifier in identifiers {
            if let hero = await AWSaryContentDataSource.shared.hero(id: identifier) {
                entities.append(AWSHeroEntity(member: hero))
            }
        }
        return entities
    }

    func suggestedEntities() async throws -> [AWSHeroEntity] {
        Array(try await allEntities().prefix(20))
    }

    func allEntities() async throws -> [AWSHeroEntity] {
        await AWSaryContentDataSource.shared.heroes().map(AWSHeroEntity.init(member:))
    }

    func entities(matching string: String) async throws -> [AWSHeroEntity] {
        await AWSaryContentDataSource.shared.heroes(matching: string).map(AWSHeroEntity.init(member:))
    }
}

extension String {
    func awsaryDisplayImage(displayStyle: DisplayRepresentation.Image.DisplayStyle = .default) -> DisplayRepresentation.Image? {
        guard let url = URL(string: self), !isEmpty else { return nil }
        return DisplayRepresentation.Image(url: url, displayStyle: displayStyle)
    }
}
